/**
 * Streaming Example with TypeScript
 * Shows real-time streaming responses from Claude
 */
import Anthropic from '@anthropic-ai/sdk';

async function streamExample() {
  const anthropic = new Anthropic({
    apiKey: process.env.ANTHROPIC_API_KEY,
  });

  console.log('Streaming response from Claude...');
  console.log('-'.repeat(50));

  try {
    const stream = await anthropic.messages.create({
      model: 'claude-sonnet-4-20250514',
      max_tokens: 1024,
      messages: [
        {
          role: 'user',
          content: 'Write a step-by-step guide for setting up a TypeScript project with best practices',
        },
      ],
      stream: true,
    });

    // Process the stream
    for await (const event of stream) {
      if (event.type === 'content_block_delta' && event.delta.type === 'text_delta') {
        process.stdout.write(event.delta.text);
      }
    }

    console.log('\n' + '-'.repeat(50));
    console.log('Streaming complete!');

  } catch (error) {
    console.error('Streaming error:', error);
  }
}

// Advanced streaming with event handling
async function advancedStreaming() {
  const anthropic = new Anthropic();

  console.log('\n\nAdvanced streaming with metadata:');
  console.log('='.repeat(50));

  const stream = await anthropic.messages.create({
    model: 'claude-sonnet-4-20250514',
    max_tokens: 2048,
    messages: [
      {
        role: 'user',
        content: 'Create a simple REST API endpoint in TypeScript using Express',
      },
    ],
    stream: true,
  });

  let fullText = '';
  let tokenCount = 0;

  for await (const event of stream) {
    switch (event.type) {
      case 'message_start':
        console.log('Message ID:', event.message.id);
        console.log('Model:', event.message.model);
        break;
      
      case 'content_block_start':
        console.log('\nStarting content block...\n');
        break;
      
      case 'content_block_delta':
        if (event.delta.type === 'text_delta') {
          process.stdout.write(event.delta.text);
          fullText += event.delta.text;
          tokenCount++;
        }
        break;
      
      case 'message_stop':
        console.log('\n\nMessage complete!');
        console.log(`Total characters: ${fullText.length}`);
        console.log(`Approximate tokens: ${tokenCount}`);
        break;
    }
  }
}

// Run examples
async function main() {
  await streamExample();
  await advancedStreaming();
}

main().catch(console.error);