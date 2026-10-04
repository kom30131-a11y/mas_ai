const DEFAULT_MODEL = 'gemini-2.5-flash';

export default {
  async fetch(request, env) {
    if (request.method === 'OPTIONS') {
      return new Response(null, {
        headers: corsHeaders(),
      });
    }

    const url = new URL(request.url);

    if (url.pathname !== '/ai') {
      return json({ error: 'Not found' }, 404);
    }

    if (request.method !== 'POST') {
      return json(
        { error: 'Method not allowed' },
        405,
      );
    }

    if (!env.GEMINI_API_KEY) {
      return json(
        { error: 'Gemini API key is not configured.' },
        500,
      );
    }

    try {
      const body = await request.json();

      if (!body || typeof body !== 'object') {
        return json(
          { error: 'Invalid AI request.' },
          400,
        );
      }

      const prompt = buildPrompt(body);

      if (!prompt.trim()) {
        return json(
          { error: 'Empty AI request.' },
          400,
        );
      }

      const model =
          env.GEMINI_MODEL ||
          DEFAULT_MODEL;

      const endpoint =
          `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent` +
          `?key=${encodeURIComponent(env.GEMINI_API_KEY)}`;

      const response = await fetch(endpoint, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          systemInstruction: {
            parts: [
              {
                text: `
You are the AI engine of MAS AI,
an adaptive medical learning application.

Follow the task and instruction supplied
by the application exactly.

Use only the supplied study content,
topics, attempts, and performance data.

Never invent study facts or performance data.

Medical terminology must be accurate.

Return valid JSON only.
Do not use Markdown.
Do not wrap JSON in code fences.

For question generation:
- Generate varied questions.
- Vary question type.
- Vary difficulty.
- Cover multiple supplied topics when possible.
- Do not repeatedly test the same fact.
- Base every question on supplied content.

For answer evaluation:
- Evaluate the student's actual answer.
- Explain why it is correct or incorrect.
- Identify the knowledge gap when present.
- Recommend the next learning action.

For performance analysis:
- Identify evidence-based strengths.
- Identify evidence-based weaknesses.
- Calculate mastery from supplied performance.
- Never claim evidence that was not supplied.

For review planning:
- Recommend review intervals based on actual performance.
- Give shorter intervals for weak or forgotten material.
- Give longer intervals for strong/mastered material.
- Return actionable recommendations.
                `.trim(),
              },
            ],
          },
          contents: [
            {
              role: 'user',
              parts: [
                {
                  text: prompt,
                },
              ],
            },
          ],
          generationConfig: {
            temperature: 0.35,
            responseMimeType: 'application/json',
          },
        }),
      });

      final data = await response.json();

      if (!response.ok) {
        return json(
          {
            error: 'Gemini request failed.',
            details: data,
          },
          response.status,
        );
      }

      const result = extractText(data);

      if (result.isEmpty) {
        return json(
          {
            error: 'Gemini returned no text.',
          },
          502,
        );
      }

      return json({
        result: result,
      });
    } catch (error) {
      return json(
        {
          error: 'AI gateway failed.',
          details: String(error),
        },
        500,
      );
    }
  },
};

function buildPrompt(body) {
  return JSON.stringify(body);
}

function extractText(data) {
  const parts =
      data?.candidates?.[0]?.content?.parts;

  if (!Array.isArray(parts)) {
    return '';
  }

  return parts
      .map((part) => part?.text || '')
      .join('')
      .trim();
}

function corsHeaders() {
  return {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers':
        'Content-Type, X-MAS-Install-Token',
    'Access-Control-Allow-Methods':
        'POST, OPTIONS',
  };
}

function json(value, status = 200) {
  return new Response(
    JSON.stringify(value),
    {
      status,
      headers: {
        ...corsHeaders(),
        'Content-Type':
            'application/json',
      },
    },
  );
                }
