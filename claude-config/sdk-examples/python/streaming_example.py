#!/usr/bin/env python3
"""
Streaming Example with Anthropic SDK
Shows how to stream responses for real-time output
"""
import os
from anthropic import Anthropic

def main():
    client = Anthropic(api_key=os.environ.get("ANTHROPIC_API_KEY"))
    
    print("Streaming response from Claude...")
    print("-" * 50)
    
    # Stream the response
    with client.messages.stream(
        model="claude-3-5-sonnet-20241022",
        max_tokens=1024,
        messages=[
            {
                "role": "user",
                "content": "Explain the concept of recursion with a simple Python example"
            }
        ]
    ) as stream:
        for event in stream:
            if event.type == "content_block_delta":
                print(event.delta.text, end="", flush=True)
    
    print("\n" + "-" * 50)
    print("Streaming complete!")

if __name__ == "__main__":
    main()