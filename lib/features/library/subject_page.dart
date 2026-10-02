import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../../core/database/database_repository.dart';

class SubjectPage extends StatefulWidget {
  final int subjectId;
  final String subjectName;
  const SubjectPage({super.key,required this.subjectId,required this.subjectName});
  @override State<SubjectPage> createState()=>_LibraryState();
}

class _LibraryState extends State<SubjectPage>{
  final repo=DatabaseRepository();
  List<Map<String,dynamic>> folders=[],content=[]; bool loading=true;

  @override void initState(){super.initState();load();}
  Future<void> load() async{
    final f=await repo.getFolders(),c=await repo.getContent();
    if(!mounted)return;
    setState((){
      folders=f.where((x)=>x['subject_id']==widget.subjectId&&x['parent_id']==null).toList();
      content=c.where((x)=>x['subject_id']==widget.subjectId&&x['folder_id']==null).toList();
      loading=false;
    });
  }

  Future<String?> nameDialog(String title,[String? old]) async{
    final c=TextEditingController(text:old);
    final r=await showDialog<String>(context:context,builder:(_)=>AlertDialog(
      title:Text(title),content:TextField(controller:c,autofocus:true),
      actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Cancel')),
        FilledButton(onPressed:()=>c.text.trim().isEmpty?null:Navigator.pop(context,c.text.trim()),child:const Text('Save'))],
    ));
    c.dispose();return r;
  }

  Future<void> folder([Map<String,dynamic>? x]) async{
    final n=await nameDialog(x==null?'New folder':'Rename folder',x?['name']);
    if(n==null)return;
    x==null?await repo.insertFolder(subjectId:widget.subjectId,parentId:null,name:n)
        :await repo.renameFolder(x['id'],n);
    await load();
  }

  Future<void> delFolder(Map<String,dynamic>x)async{
    if(await confirm('Delete folder?','The folder will be deleted.')){await repo.deleteFolder(x['id']);await load();}
  }

  Future<bool> confirm(String title,String message)async=>
    await showDialog<bool>(context:context,builder:(_)=>AlertDialog(
      title:Text(title),content:Text(message),
      actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('Cancel')),
        FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('Delete'))],
    ))??false;

  Future<void> addContent({int? folderId})async{
    final t=await showModalBottomSheet<String>(context:context,builder:(_)=>Column(
      mainAxisSize:MainAxisSize.min,children:[
        _TypeTile('PDF','pdf',Icons.picture_as_pdf_outlined),
        _TypeTile('Word','word',Icons.description_outlined),
        _TypeTile('PowerPoint','ppt',Icons.slideshow_outlined),
        _TypeTile('Text','text',Icons.edit_note_outlined),
        _TypeTile('Image','image',Icons.image_outlined),
      ]));
    if(t==null)return;
    if(t=='text'){
      await Navigator.push(context,MaterialPageRoute(builder:(_)=>TextEditorPage(
        subjectId:widget.subjectId,folderId:folderId)));
      await load();return;
    }
    final ex=switch(t){'pdf'=>['pdf'],'word'=>['doc','docx'],'ppt'=>['ppt','pptx'],'image'=>['jpg','jpeg','png','webp'],_=>[]};
    final fs=await FilePicker.pickFiles(type:FileType.custom,allowedExtensions:ex);
    if(fs.isEmpty)return;
    final f=fs.first;if(f.path==null)return;
    final id=await repo.insertContent(
      subjectId:widget.subjectId,topicId:null,folderId:folderId,
      title:p.basenameWithoutExtension(f.path!),type:typeName(t),
      content:null,filePath:f.path,originalFileName:f.name,
      createdAt:DateTime.now().toIso8601String());
    await repo.insertFile(contentId:id,path:f.path!,name:f.name,mimeType:mime(t));
    await load();
  }

  Future<void> renameContent(Map<String,dynamic>x)async{
    final n=await nameDialog('Rename',x['title']);
    if(n!=null){await repo.updateContent(contentId:x['id'],title:n);await load();}
  }

  Future<void> delContent(Map<String,dynamic>x)async{
    if(await confirm('Delete content?','This content will be removed.')){
      await repo.deleteContent(x['id']);await load();
    }
  }

  Future<void> openContent(Map<String,dynamic>x,{int? folderId})async{
    if(x['type']=='Text'){
      await Navigator.push(context,MaterialPageRoute(builder:(_)=>TextEditorPage(
        subjectId:widget.subjectId,folderId:folderId,contentItem:x)));
      await load();
    }
  }

  Widget item(Map<String,dynamic>x,bool isFolder){
    final title=isFolder?x['name']:(x['title']??'Untitled');
    return ListTile(
      leading:Icon(isFolder?Icons.folder_outlined:icon(x['type'])),
      title:Text(title),
      onTap:()=>isFolder
        ?Navigator.push(context,MaterialPageRoute(builder:(_)=>FolderPage(
          subjectId:widget.subjectId,folderId:x['id'],folderName:x['name']))).then((_){load();})
        :openContent(x),
      trailing:PopupMenuButton<String>(
        onSelected:(v)=>isFolder
          ?(v=='rename'?folder(x):delFolder(x))
          :(v=='rename'?renameContent(x):delContent(x)),
        itemBuilder:(_)=>[
          PopupMenuItem(value:'rename',child:Text(isFolder?'Rename folder':'Rename')),
          PopupMenuItem(value:'delete',child:Text(isFolder?'Delete folder':'Delete')),
        ]),
    );
  }

  Widget section(String title,List<Map<String,dynamic>> data,bool f){
    if(data.isEmpty)return const SizedBox.shrink();
    return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Padding(padding:const EdgeInsets.fromLTRB(16,16,16,8),
        child:Text(title,style:Theme.of(context).textTheme.titleMedium)),
      ...data.map((x)=>item(x,f)),
    ]);
  }

  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:Text(widget.subjectName),actions:[
      IconButton(onPressed:()=>folder(),icon:const Icon(Icons.create_new_folder_outlined)),
      IconButton(onPressed:()=>addContent(),icon:const Icon(Icons.add)),
    ]),
    body:loading?const Center(child:CircularProgressIndicator()):RefreshIndicator(
      onRefresh:load,child:ListView(children:[
        section('Folders',folders,true),section('Content',content,false),
      ])),
  );
}

class FolderPage extends StatefulWidget{
  final int subjectId,folderId;final String folderName;
  const FolderPage({super.key,required this.subjectId,required this.folderId,required this.folderName});
  @override State<FolderPage> createState()=>_FolderState();
}

class _FolderState extends State<FolderPage>{
  final repo=DatabaseRepository();
  List<Map<String,dynamic>> folders=[],content=[];bool loading=true;

  @override void initState(){super.initState();load();}
  Future<void> load()async{
    final f=await repo.getFolders(widget.folderId),c=await repo.getContent(folderId:widget.folderId);
    if(mounted)setState(()=>{folders=f,content=c,loading=false});
  }

  Future<String?> dialog(String title,[String? old])async{
    final c=TextEditingController(text:old);
    final r=await showDialog<String>(context:context,builder:(_)=>AlertDialog(
      title:Text(title),content:TextField(controller:c,autofocus:true),
      actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Cancel')),
        FilledButton(onPressed:()=>c.text.trim().isEmpty?null:Navigator.pop(context,c.text.trim()),child:const Text('Save'))]));
    c.dispose();return r;
  }

  Future<void> newFolder([Map<String,dynamic>?x])async{
    final n=await dialog(x==null?'New folder':'Rename folder',x?['name']);
    if(n==null)return;
    x==null?await repo.insertFolder(subjectId:widget.subjectId,parentId:widget.folderId,name:n)
      :await repo.renameFolder(x['id'],n);
    await load();
  }

  Future<void> removeFolder(Map<String,dynamic>x)async{
    if(await _confirm('Delete folder?')){
      await repo.deleteFolder(x['id']);await load();
    }
  }

  Future<bool> _confirm(String title)async=>await showDialog<bool>(context:context,builder:(_)=>AlertDialog(
    title:Text(title),content:const Text('This item will be deleted.'),
    actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('Cancel')),
      FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('Delete'))]))??false;

  Future<void> add()async{
    final t=await showModalBottomSheet<String>(context:context,builder:(_)=>Column(
      mainAxisSize:MainAxisSize.min,children:[
        _TypeTile('PDF','pdf',Icons.picture_as_pdf_outlined),
        _TypeTile('Word','word',Icons.description_outlined),
        _TypeTile('PowerPoint','ppt',Icons.slideshow_outlined),
        _TypeTile('Text','text',Icons.edit_note_outlined),
        _TypeTile('Image','image',Icons.image_outlined),
      ]));
    if(t==null)return;
    if(t=='text'){
      await Navigator.push(context,MaterialPageRoute(builder:(_)=>TextEditorPage(
        subjectId:widget.subjectId,folderId:widget.folderId)));
      await load();return;
    }
    final ex=switch(t){'pdf'=>['pdf'],'word'=>['doc','docx'],'ppt'=>['ppt','pptx'],'image'=>['jpg','jpeg','png','webp'],_=>[]};
    final fs=await FilePicker.pickFiles(type:FileType.custom,allowedExtensions:ex);
    if(fs.isEmpty)return;
    final f=fs.first;if(f.path==null)return;
    final id=await repo.insertContent(subjectId:widget.subjectId,topicId:null,folderId:widget.folderId,
      title:p.basenameWithoutExtension(f.path!),type:typeName(t),content:null,filePath:f.path,
      originalFileName:f.name,createdAt:DateTime.now().toIso8601String());
    await repo.insertFile(contentId:id,path:f.path!,name:f.name,mimeType:mime(t));await load();
  }

  Future<void> rename(Map<String,dynamic>x)async{
    final n=await dialog('Rename',x['title']);if(n!=null){
      await repo.updateContent(contentId:x['id'],title:n);await load();
    }
  }

  Future<void> remove(Map<String,dynamic>x)async{
    if(await _confirm('Delete content?')){await repo.deleteContent(x['id']);await load();}
  }

  Widget item(Map<String,dynamic>x,bool f){
    final title=f?x['name']:(x['title']??'Untitled');
    return ListTile(
      leading:Icon(f?Icons.folder_outlined:icon(x['type'])),title:Text(title),
      onTap:()=>f?Navigator.push(context,MaterialPageRoute(builder:(_)=>FolderPage(
        subjectId:widget.subjectId,folderId:x['id'],folderName:x['name']))).then((_){load();})
        :x['type']=='Text'?Navigator.push(context,MaterialPageRoute(builder:(_)=>TextEditorPage(
          subjectId:widget.subjectId,folderId:widget.folderId,contentItem:x))).then((_){load();}):null,
      trailing:PopupMenuButton<String>(
        onSelected:(v)=>f?(v=='rename'?newFolder(x):removeFolder(x)):(v=='rename'?rename(x):remove(x)),
        itemBuilder:(_)=>[
          PopupMenuItem(value:'rename',child:Text(f?'Rename folder':'Rename')),
          PopupMenuItem(value:'delete',child:Text(f?'Delete folder':'Delete'))]));
  }

  Widget section(String t,List<Map<String,dynamic>>d,bool f)=>d.isEmpty?const SizedBox.shrink():
    Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Padding(padding:const EdgeInsets.fromLTRB(16,16,16,8),child:Text(t,style:Theme.of(context).textTheme.titleMedium)),
      ...d.map((x)=>item(x,f))]);

  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:Text(widget.folderName),actions:[
      IconButton(onPressed:()=>newFolder(),icon:const Icon(Icons.create_new_folder_outlined)),
      IconButton(onPressed:add,icon:const Icon(Icons.add))]),
    body:loading?const Center(child:CircularProgressIndicator()):RefreshIndicator(
      onRefresh:load,child:ListView(children:[section('Folders',folders,true),section('Content',content,false)])));
}

class TextEditorPage extends StatefulWidget{
  final int subjectId;final int? folderId;final Map<String,dynamic>? contentItem;
  const TextEditorPage({super.key,required this.subjectId,required this.folderId,this.contentItem});
  @override State<TextEditorPage> createState()=>_TextEditorState();
}

class _TextEditorState extends State<TextEditorPage>{
  final repo=DatabaseRepository();late TextEditingController title,text;

  @override void initState(){super.initState();
    title=TextEditingController(text:widget.contentItem?['title']??'');
    text=TextEditingController(text:widget.contentItem?['content']??'');
  }
  @override void dispose(){title.dispose();text.dispose();super.dispose();}

  Future<void> save()async{
    if(title.text.trim().isEmpty)return;
    if(widget.contentItem!=null){
      await repo.updateContent(contentId:widget.contentItem!['id'],title:title.text.trim(),content:text.text);
    }else{
      await repo.insertContent(subjectId:widget.subjectId,topicId:null,folderId:widget.folderId,
        title:title.text.trim(),type:'Text',content:text.text,filePath:null,originalFileName:null,
        createdAt:DateTime.now().toIso8601String());
    }
    if(mounted)Navigator.pop(context);
  }

  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:Text(widget.contentItem==null?'New text':'Edit text'),
      actions:[IconButton(onPressed:save,icon:const Icon(Icons.save_outlined))]),
    body:Padding(padding:const EdgeInsets.all(16),child:Column(children:[
      TextField(controller:title,decoration:const InputDecoration(labelText:'Title',border:OutlineInputBorder())),
      const SizedBox(height:16),
      Expanded(child:TextField(controller:text,expands:true,maxLines:null,minLines:null,
        textAlignVertical:TextAlignVertical.top,
        decoration:const InputDecoration(labelText:'Text',alignLabelWithHint:true,border:OutlineInputBorder())))
    ])));
}

class _TypeTile extends StatelessWidget{
  final String title,value;final IconData icon;
  const _TypeTile(this.title,this.value,this.icon);
  @override Widget build(BuildContext c)=>ListTile(
    leading:Icon(icon),title:Text(title),onTap:()=>Navigator.pop(c,value));
}

String typeName(String t)=>switch(t){
  'pdf'=>'PDF','word'=>'Word','ppt'=>'PowerPoint','image'=>'Image',_=>'Text'};

String? mime(String t)=>switch(t){
  'pdf'=>'application/pdf','word'=>'application/msword',
  'ppt'=>'application/vnd.ms-powerpoint','image'=>'image/*',_=>null};

IconData icon(String? t)=>switch(t){
  'PDF'=>Icons.picture_as_pdf_outlined,'Word'=>Icons.description_outlined,
  'PowerPoint'=>Icons.slideshow_outlined,'Image'=>Icons.image_outlined,
  'Text'=>Icons.article_outlined,_=>Icons.insert_drive_file_outlined};
