import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../../core/database/database_repository.dart';

final repo = DatabaseRepository.instance;

class SubjectPage extends StatefulWidget {
  final int subjectId; final String subjectName;
  const SubjectPage({super.key,required this.subjectId,required this.subjectName});
  @override State<SubjectPage> createState()=>_SubjectState();
}

class _SubjectState extends State<SubjectPage>{
  List<Map<String,dynamic>> folders=[],content=[]; bool loading=true;

  @override void initState(){super.initState();load();}
  Future<void> load()async{
    final f=await repo.getFolders(),c=await repo.getContent();
    if(!mounted)return;
    setState((){folders=f.where((x)=>x['subject_id']==widget.subjectId&&x['parent_id']==null).toList();
      content=c.where((x)=>x['subject_id']==widget.subjectId&&x['folder_id']==null).toList();loading=false;});
  }

  Future<String?> dialog(String title,[String? old])async{
    final c=TextEditingController(text:old);
    final r=await showDialog<String>(context:context,builder:(_)=>AlertDialog(
      title:Text(title),content:TextField(controller:c,autofocus:true),
      actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Cancel')),
      FilledButton(onPressed:()=>c.text.trim().isEmpty?null:Navigator.pop(context,c.text.trim()),child:const Text('Save'))]));
    c.dispose();return r;
  }

  Future<void> folder([Map<String,dynamic>? x])async{
    final n=await dialog(x==null?'New folder':'Rename folder',x?['name']);if(n==null)return;
    x==null?await repo.insertFolder(name:n,subjectId:widget.subjectId)
      :await repo.renameFolder(folderId:x['id'],name:n);await load();
  }

  Future<void> deleteFolder(Map<String,dynamic>x)async{
    if(await confirm('Delete folder?')){await repo.deleteFolder(x['id']);await load();}
  }

  Future<bool> confirm(String title)async=>await showDialog<bool>(context:context,builder:(_)=>AlertDialog(
    title:Text(title),content:const Text('This item will be deleted.'),
    actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('Cancel')),
    FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('Delete'))]))??false;

  Future<void> add({int? folderId})async{
    final t=await showModalBottomSheet<String>(context:context,builder:(_)=>Column(
      mainAxisSize:MainAxisSize.min,children:[
      for(final x:[['PDF','pdf',Icons.picture_as_pdf_outlined],['Word','word',Icons.description_outlined],
        ['PowerPoint','ppt',Icons.slideshow_outlined],['Text','text',Icons.edit_note_outlined],
        ['Image','image',Icons.image_outlined]])
        ListTile(leading:Icon(x[2] as IconData),title:Text(x[0] as String),
          onTap:()=>Navigator.pop(context,x[1]))]));
    if(t==null)return;
    if(t=='text'){
      await Navigator.push(context,MaterialPageRoute(builder:(_)=>TextEditor(
        subjectId:widget.subjectId,folderId:folderId)));if(mounted)load();return;
    }
    final ex=<String>[];
    ex.addAll(t=='pdf'?['pdf']:t=='word'?['doc','docx']:t=='ppt'?['ppt','pptx']:['jpg','jpeg','png','webp']);
    final fs=await FilePicker.pickFiles(type:FileType.custom,allowedExtensions:ex);
    if(fs.isEmpty)return;
    final f=fs.first;if(f.path==null)return;
    final id=await repo.insertContent({
      'subject_id':widget.subjectId,'topic_id':null,'folder_id':folderId,
      'title':p.basenameWithoutExtension(f.path!), 'type':typeName(t),
      'content':null,'file_path':f.path,'original_file_name':f.name,
      'created_at':DateTime.now().toIso8601String()});
    await repo.insertFile({'content_id':id,'path':f.path,'name':f.name,'mime_type':mime(t)});
    await load();
  }

  Future<void> rename(Map<String,dynamic>x)async{
    final n=await dialog('Rename',x['title']);if(n!=null){await repo.updateContent(contentId:x['id'],title:n);await load();}
  }

  Future<void> deleteContent(Map<String,dynamic>x)async{
    if(await confirm('Delete content?')){await repo.deleteContent(x['id']);await load();}
  }

  Widget item(Map<String,dynamic>x,bool f){
    final title=f?x['name']:(x['title']??'Untitled');
    return ListTile(
      leading:Icon(f?Icons.folder_outlined:icon(x['type'])),title:Text(title),
      onTap:()=>f?Navigator.push(context,MaterialPageRoute(builder:(_)=>FolderPage(
        subjectId:widget.subjectId,folderId:x['id'],folderName:x['name']))).then((_){load();})
        :x['type']=='Text'?Navigator.push(context,MaterialPageRoute(builder:(_)=>TextEditor(
          subjectId:widget.subjectId,folderId:null,item:x))).then((_){load();}):null,
      trailing:PopupMenuButton<String>(
        onSelected:(v)=>f?(v=='r'?folder(x):deleteFolder(x)):(v=='r'?rename(x):deleteContent(x)),
        itemBuilder:(_)=>[PopupMenuItem(value:'r',child:Text(f?'Rename folder':'Rename')),
          PopupMenuItem(value:'d',child:Text(f?'Delete folder':'Delete'))]));
  }

  Widget section(String t,List<Map<String,dynamic>>d,bool f)=>d.isEmpty?const SizedBox():
    Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Padding(padding:const EdgeInsets.fromLTRB(16,16,16,8),child:Text(t)),
      ...d.map((x)=>item(x,f))]);

  @override Widget build(BuildContext c)=>Scaffold(
    appBar:AppBar(title:Text(widget.subjectName),actions:[
      IconButton(onPressed:()=>folder(),icon:const Icon(Icons.create_new_folder_outlined)),
      IconButton(onPressed:()=>add(),icon:const Icon(Icons.add))]),
    body:loading?const Center(child:CircularProgressIndicator()):RefreshIndicator(
      onRefresh:load,child:ListView(children:[section('Folders',folders,true),section('Content',content,false)])));
}

class FolderPage extends StatefulWidget{
  final int subjectId,folderId;final String folderName;
  const FolderPage({super.key,required this.subjectId,required this.folderId,required this.folderName});
  @override State<FolderPage> createState()=>_FolderState();
}

class _FolderState extends State<FolderPage>{
  List<Map<String,dynamic>> folders=[],content=[];bool loading=true;
  @override void initState(){super.initState();load();}
  Future<void> load()async{
    final f=await repo.getFolders(parentId:widget.folderId),c=await repo.getContent(folderId:widget.folderId);
    if(mounted)setState((){folders=f;content=c;loading=false;});
  }

  Future<String?> dialog(String title,[String? old])async{
    final c=TextEditingController(text:old);
    final r=await showDialog<String>(context:context,builder:(_)=>AlertDialog(
      title:Text(title),content:TextField(controller:c,autofocus:true),
      actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Cancel')),
      FilledButton(onPressed:()=>c.text.trim().isEmpty?null:Navigator.pop(context,c.text.trim()),child:const Text('Save'))]));
    c.dispose();return r;
  }

  Future<void> folder([Map<String,dynamic>?x])async{
    final n=await dialog(x==null?'New folder':'Rename folder',x?['name']);if(n==null)return;
    x==null?await repo.insertFolder(name:n,parentId:widget.folderId,subjectId:widget.subjectId)
      :await repo.renameFolder(folderId:x['id'],name:n);await load();
  }

  Future<void> deleteFolder(Map<String,dynamic>x)async{
    if(await confirm('Delete folder?')){await repo.deleteFolder(x['id']);await load();}
  }

  Future<bool> confirm(String title)async=>await showDialog<bool>(context:context,builder:(_)=>AlertDialog(
    title:Text(title),content:const Text('This item will be deleted.'),
    actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('Cancel')),
    FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('Delete'))]))??false;

  Future<void> add()async{
    final s=SubjectPage(subjectId:widget.subjectId,subjectName:'');
    final key=s;
    await _addContent(widget.subjectId,widget.folderId,context);
    await load();
  }

  Future<void> rename(Map<String,dynamic>x)async{
    final n=await dialog('Rename',x['title']);if(n!=null){await repo.updateContent(contentId:x['id'],title:n);await load();}
  }

  Future<void> deleteContent(Map<String,dynamic>x)async{
    if(await confirm('Delete content?')){await repo.deleteContent(x['id']);await load();}
  }

  Widget item(Map<String,dynamic>x,bool f){
    final title=f?x['name']:(x['title']??'Untitled');
    return ListTile(
      leading:Icon(f?Icons.folder_outlined:icon(x['type'])),title:Text(title),
      onTap:()=>f?Navigator.push(context,MaterialPageRoute(builder:(_)=>FolderPage(
        subjectId:widget.subjectId,folderId:x['id'],folderName:x['name']))).then((_){load();})
        :x['type']=='Text'?Navigator.push(context,MaterialPageRoute(builder:(_)=>TextEditor(
          subjectId:widget.subjectId,folderId:widget.folderId,item:x))).then((_){load();}):null,
      trailing:PopupMenuButton<String>(
        onSelected:(v)=>f?(v=='r'?folder(x):deleteFolder(x)):(v=='r'?rename(x):deleteContent(x)),
        itemBuilder:(_)=>[PopupMenuItem(value:'r',child:Text(f?'Rename folder':'Rename')),
          PopupMenuItem(value:'d',child:Text(f?'Delete folder':'Delete'))]));
  }

  Widget section(String t,List<Map<String,dynamic>>d,bool f)=>d.isEmpty?const SizedBox():
    Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Padding(padding:const EdgeInsets.fromLTRB(16,16,16,8),child:Text(t)),
      ...d.map((x)=>item(x,f))]);

  @override Widget build(BuildContext c)=>Scaffold(
    appBar:AppBar(title:Text(widget.folderName),actions:[
      IconButton(onPressed:()=>folder(),icon:const Icon(Icons.create_new_folder_outlined)),
      IconButton(onPressed:add,icon:const Icon(Icons.add))]),
    body:loading?const Center(child:CircularProgressIndicator()):RefreshIndicator(
      onRefresh:load,child:ListView(children:[section('Folders',folders,true),section('Content',content,false)])));
}

Future<void> _addContent(int subjectId,int? folderId,BuildContext context)async{
  final t=await showModalBottomSheet<String>(context:context,builder:(_)=>Column(
    mainAxisSize:MainAxisSize.min,children:[
    for(final x:[['PDF','pdf',Icons.picture_as_pdf_outlined],['Word','word',Icons.description_outlined],
      ['PowerPoint','ppt',Icons.slideshow_outlined],['Text','text',Icons.edit_note_outlined],
      ['Image','image',Icons.image_outlined]])
      ListTile(leading:Icon(x[2] as IconData),title:Text(x[0] as String),
        onTap:()=>Navigator.pop(context,x[1]))]));
  if(t==null)return;
  if(t=='text'){
    await Navigator.push(context,MaterialPageRoute(builder:(_)=>TextEditor(subjectId:subjectId,folderId:folderId)));return;
  }
  final ex=<String>[]..addAll(t=='pdf'?['pdf']:t=='word'?['doc','docx']:t=='ppt'?['ppt','pptx']:['jpg','jpeg','png','webp']);
  final fs=await FilePicker.pickFiles(type:FileType.custom,allowedExtensions:ex);
  if(fs.isEmpty)return;final f=fs.first;if(f.path==null)return;
  final id=await repo.insertContent({
    'subject_id':subjectId,'topic_id':null,'folder_id':folderId,
    'title':p.basenameWithoutExtension(f.path!),'type':typeName(t),'content':null,
    'file_path':f.path,'original_file_name':f.name,'created_at':DateTime.now().toIso8601String()});
  await repo.insertFile({'content_id':id,'path':f.path,'name':f.name,'mime_type':mime(t)});
}

class TextEditor extends StatefulWidget{
  final int subjectId;final int? folderId;final Map<String,dynamic>? item;
  const TextEditor({super.key,required this.subjectId,required this.folderId,this.item});
  @override State<TextEditor> createState()=>_TextEditorState();
}

class _TextEditorState extends State<TextEditor>{
  late TextEditingController title,text;
  @override void initState(){super.initState();
    title=TextEditingController(text:widget.item?['title']??'');
    text=TextEditingController(text:widget.item?['content']??'');}
  @override void dispose(){title.dispose();text.dispose();super.dispose();}

  Future<void> save()async{
    if(title.text.trim().isEmpty)return;
    widget.item==null?await repo.insertContent({
      'subject_id':widget.subjectId,'topic_id':null,'folder_id':widget.folderId,
      'title':title.text.trim(),'type':'Text','content':text.text,
      'file_path':null,'original_file_name':null,'created_at':DateTime.now().toIso8601String()})
      :await repo.updateContent(contentId:widget.item!['id'],title:title.text.trim(),content:text.text);
    if(mounted)Navigator.pop(context);
  }

  @override Widget build(BuildContext c)=>Scaffold(
    appBar:AppBar(title:Text(widget.item==null?'New text':'Edit text'),
      actions:[IconButton(onPressed:save,icon:const Icon(Icons.save_outlined))]),
    body:Padding(padding:const EdgeInsets.all(16),child:Column(children:[
      TextField(controller:title,decoration:const InputDecoration(labelText:'Title')),
      const SizedBox(height:12),Expanded(child:TextField(controller:text,expands:true,
        maxLines:null,minLines:null,textAlignVertical:TextAlignVertical.top,
        decoration:const InputDecoration(labelText:'Text',border:OutlineInputBorder())))])));
}

String typeName(String t)=>switch(t){'pdf'=>'PDF','word'=>'Word','ppt'=>'PowerPoint','image'=>'Image',_=>'Text'};
String? mime(String t)=>switch(t){'pdf'=>'application/pdf','word'=>'application/msword',
'ppt'=>'application/vnd.ms-powerpoint','image'=>'image/*',_=>null};
IconData icon(String? t)=>switch(t){'PDF'=>Icons.picture_as_pdf_outlined,'Word'=>Icons.description_outlined,
'PowerPoint'=>Icons.slideshow_outlined,'Image'=>Icons.image_outlined,'Text'=>Icons.article_outlined,
_=>Icons.insert_drive_file_outlined};
