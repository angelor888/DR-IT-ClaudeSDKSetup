#!/usr/bin/env python3
"""
Basic Anthropic SDK Example
Demonstrates simple message creation with Claude
"""
import os
import anthropic
from anthropic import Anthropic

def main():
    # Initialize the client
    client = Anthropic(
        # This will use ANTHROPIC_API_KEY env variable by default
        api_key=os.environ.get("ANTHROPIC_API_KEY")
    )
    
    # Simple message example
    message = client.messages.create(
        model="claude-3-5-sonnet-20241022",
        max_tokens=1024,
        messages=[
            {
                "role": "user",
                "content": "Write a haiku about Python programming"
            }
        ]
    )
    
    print("Claude's Response:")
    print(message.content[0].text)
    
    # Example with system prompt
    message = client.messages.create(
        model="claude-3-5-sonnet-20241022",
        max_tokens=1024,
        system="You are a helpful coding assistant who responds concisely.",
        messages=[
            {
                "role": "user",
                "content": "What are the benefits of using type hints in Python?"
            }
        ]
    )
    
    print("\nWith System Prompt:")
    print(message.content[0].text)

if __name__ == "__main__":
    main()