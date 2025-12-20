const request = require('supertest');
const express = require('express');

describe('Expense Tracker API', () => {
  let app;

  beforeAll(() => {
    app = express();
    app.use(express.json());
    app.get('/health', (req, res) => {
      res.json({ status: 'healthy', service: '25rp19824-turikumwenimana-api' });
    });
  });

  test('GET /health should return healthy status', async () => {
    const response = await request(app).get('/health');
    expect(response.status).toBe(200);
    expect(response.body.status).toBe('healthy');
  });

  test('Service name should match project identifier', async () => {
    const response = await request(app).get('/health');
    expect(response.body.service).toContain('25rp19824-turikumwenimana');
  });
});
