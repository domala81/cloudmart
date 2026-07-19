#!/usr/bin/env node
// Creates the "CloudMart Customer Support" OpenAI assistant and prints its id.
// Replaces the manual dashboard steps in the Notion Day-4 guide.
//
// Usage:
//   export OPENAI_API_KEY=sk-...
//   npm install --prefix scripts
//   node scripts/bootstrap-openai-assistant.mjs
//
// Copy the printed id into infra/terraform.tfvars as openai_assistant_id.

import OpenAI from "openai";

const apiKey = process.env.OPENAI_API_KEY;
if (!apiKey) {
  console.error("Error: OPENAI_API_KEY is not set.");
  process.exit(1);
}

const INSTRUCTIONS =
  "You are a customer support agent for CloudMart, an e-commerce platform. " +
  "Your role is to assist customers with general inquiries, order issues, and " +
  "provide helpful information about using the CloudMart platform. You don't have " +
  "direct access to specific product or inventory information. Always be polite, " +
  "patient, and focus on providing excellent customer service. If a customer asks " +
  "about specific products or inventory, politely explain that you don't have access " +
  "to that information and suggest they check the website or speak with a sales representative.";

const openai = new OpenAI({ apiKey });

const assistant = await openai.beta.assistants.create({
  name: "CloudMart Customer Support",
  model: "gpt-4o",
  instructions: INSTRUCTIONS,
});

console.log("Created OpenAI assistant.");
console.log(`OPENAI_ASSISTANT_ID=${assistant.id}`);
console.log("\nAdd this to infra/terraform.tfvars:");
console.log(`openai_assistant_id = "${assistant.id}"`);
