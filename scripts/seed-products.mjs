#!/usr/bin/env node
// Seeds the cloudmart-products DynamoDB table with sample products so the
// storefront and Bedrock recommendation agent have data to work with.
//
// Usage:
//   export AWS_REGION=us-east-1   (and AWS credentials in your environment)
//   npm install --prefix scripts
//   node scripts/seed-products.mjs

import { randomUUID } from "node:crypto";
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, PutCommand } from "@aws-sdk/lib-dynamodb";

const region = process.env.AWS_REGION || "us-east-1";
const TABLE = "cloudmart-products";

const client = DynamoDBDocumentClient.from(new DynamoDBClient({ region }));

const products = [
  { name: "Aurora Wireless Headphones", price: 129.99, description: "Over-ear noise-cancelling headphones with 30-hour battery life." },
  { name: "Nimbus Mechanical Keyboard", price: 89.5, description: "Hot-swappable 75% mechanical keyboard with RGB backlight." },
  { name: "Vega 4K Webcam", price: 74.0, description: "4K webcam with auto-framing and dual noise-reducing mics." },
  { name: "Orbit Smart Water Bottle", price: 34.99, description: "Tracks hydration and glows to remind you to drink." },
  { name: "Ember Travel Mug", price: 24.95, description: "Double-walled stainless steel mug that keeps drinks hot for 6 hours." },
  { name: "Pulse Fitness Band", price: 59.0, description: "Heart-rate and sleep tracking band with 10-day battery." },
];

for (const p of products) {
  const item = {
    id: randomUUID().split("-")[0],
    ...p,
    image: "",
    createdAt: new Date().toISOString(),
  };
  await client.send(new PutCommand({ TableName: TABLE, Item: item }));
  console.log(`Seeded: ${item.name} (${item.id})`);
}

console.log(`\nDone. Seeded ${products.length} products into ${TABLE}.`);
