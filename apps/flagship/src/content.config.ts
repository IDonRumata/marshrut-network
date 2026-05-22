import { defineCollection, z } from 'astro:content';
import { glob } from 'astro/loaders';

const book = defineCollection({
  loader: glob({ pattern: '**/*.md', base: './src/content/book' }),
  schema: z.object({
    title: z.string(),
    subtitle: z.string().optional(),
    chapterNumber: z.number().int().positive(),
    publishedAt: z.coerce.date(),
    isFree: z.boolean().default(true),
    audioUrl: z.string().url().optional(),
    readingTimeMin: z.number().int().positive(),
    previewText: z.string().min(20).max(400),
    tags: z.array(z.string()).default([]),
    sourceId: z.string().optional(),
    seo: z.object({
      title: z.string().optional(),
      description: z.string().optional(),
      ogImage: z.string().optional(),
    }).optional(),
  }),
});

const diary = defineCollection({
  loader: glob({ pattern: '**/*.md', base: './src/content/diary' }),
  schema: z.object({
    title: z.string(),
    publishedAt: z.coerce.date(),
    location: z.string().optional(),
    mood: z.string().optional(),
    tags: z.array(z.string()).default([]),
    sourceId: z.string().optional(),
    seo: z.object({
      title: z.string().optional(),
      description: z.string().optional(),
    }).optional(),
  }),
});

export const collections = { book, diary };
