#!/usr/bin/env ruby
# file: loremaster-chat.rb

require 'ollama-ai'
require 'fileutils'

MODEL = ARGV[0] || 'llama3.2'
STYLE_PROMPT = "You must always respond in an in-universe way, as a scholarly Elezen from Sharlayan named Elianore Quasarion. You reply in a scholarly way, with occasional Shakespearean affectations."
CONTEXT_FILE = 'encyclopedia.txt'
OLLAMA_HOST = ENV['OLLAMA_HOST'] || 'http://192.168.0.60:11434'
TRANSCRIPT_FILE = "chatlog_#{Time.now.strftime('%Y%m%d_%H%M%S')}.md"

# Initialize the Ollama client with custom host
client = Ollama.new({ credentials: { address: OLLAMA_HOST } })

# Load system context from file, if exists
encyclopedia_context = if File.exist?(CONTEXT_FILE)
  File.read(CONTEXT_FILE).strip
else
  ""
end

# Compose full system prompt with style + context
system_prompt = "#{STYLE_PROMPT}\n\n#{encyclopedia_context}"

# Initialize chat history with composed system prompt
chat_history = [
  { role: 'system', content: system_prompt }
]

# Initialize markdown transcript
File.write(TRANSCRIPT_FILE, "# Chat Transcript\n\n**Model:** #{MODEL}\n**Host:** #{OLLAMA_HOST}\n**Context Source:** #{CONTEXT_FILE}\n\n")

puts "\e[1;36m🤖 Loremaster Chatbot using model: #{MODEL}\e[0m"
puts "Connected to: #{OLLAMA_HOST}"
puts "Loaded context from: #{CONTEXT_FILE}"
puts "Transcript file: #{TRANSCRIPT_FILE}"
puts "Type 'exit' or Ctrl+C to quit.\n"

loop do
  print "\e[1;32mYou:\e[0m "
  input = gets&.chomp
  break if input.nil? || input.strip.downcase == 'exit'

  styled_input = "#{STYLE_PROMPT}\n\n#{input}"
  chat_history << { role: 'user', content: styled_input }
  File.open(TRANSCRIPT_FILE, 'a') { |f| f.puts("**You:** #{input}\n") }

  begin
    response = client.chat({ model: MODEL, messages: chat_history })
    reply = response.map { |chunk| chunk["message"]["content"] }.join
    puts "\e[1;34mLoremaster:\e[0m #{reply}\n"

    chat_history << { role: 'assistant', content: reply }
    File.open(TRANSCRIPT_FILE, 'a') { |f| f.puts("**#{MODEL}:** #{reply}\n") }
  rescue => e
    puts "[Error] #{e.message}"
  end
end

puts "\n👋 Chat ended. Transcript saved to #{TRANSCRIPT_FILE}"
