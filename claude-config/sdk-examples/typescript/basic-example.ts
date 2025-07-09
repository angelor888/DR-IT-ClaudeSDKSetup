/**
 * Basic TypeScript Example with Anthropic SDK
 * Demonstrates message creation and type safety
 */
import Anthropic from '@anthropic-ai/sdk';
import type { Message } from '@anthropic-ai/sdk/resources/messages';

async function main() {
  // Initialize the client
  const anthropic = new Anthropic({
    apiKey: process.env.ANTHROPIC_API_KEY, // defaults to this env var
  });

  try {
    // Simple message example
    const message: Message = await anthropic.messages.create({
      model: 'claude-sonnet-4-20250514',
      max_tokens: 1024,
      messages: [
        {
          role: 'user',
          content: 'Write a TypeScript function that reverses a string',
        },
      ],
    });

    console.log('Claude\'s Response:');
    console.log(message.content[0].text);

    // Example with system prompt and temperature
    const analyticalResponse = await anthropic.messages.create({
      model: 'claude-sonnet-4-20250514',
      max_tokens: 1024,
      temperature: 0.2, // Lower temperature for more focused responses
      system: 'You are a TypeScript expert. Provide type-safe, modern code examples.',
      messages: [
        {
          role: 'user',
          content: 'Show me how to create a generic type-safe event emitter in TypeScript',
        },
      ],
    });

    console.log('\nWith System Prompt and Low Temperature:');
    console.log(analyticalResponse.content[0].text);

  } catch (error) {
    console.error('Error calling Claude API:', error);
  }
}

// Run the example
main();