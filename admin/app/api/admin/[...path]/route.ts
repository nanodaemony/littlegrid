import { NextRequest, NextResponse } from 'next/server'

const BACKEND_URL = process.env.NEXT_PUBLIC_BACKEND_URL || 'http://localhost:8000'

export async function POST(request: NextRequest, context: { params: Promise<{ path: string[] }> }) {
  const params = await context.params
  const path = params.path.join('/')
  const body = await request.json()
  const token = request.headers.get('authorization')
  const traceId = request.headers.get('x-trace-id') || crypto.randomUUID()

  const res = await fetch(`${BACKEND_URL}/api/admin/${path}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-Trace-Id': traceId,
      ...(token ? { 'Authorization': token } : {}),
    },
    body: JSON.stringify(body),
  })

  const data = await res.json()
  const response = NextResponse.json(data, { status: res.status })
  response.headers.set('X-Trace-Id', res.headers.get('X-Trace-Id') || traceId)
  return response
}

export async function GET(request: NextRequest, context: { params: Promise<{ path: string[] }> }) {
  const params = await context.params
  const path = params.path.join('/')
  const token = request.headers.get('authorization')
  const traceId = request.headers.get('x-trace-id') || crypto.randomUUID()

  const res = await fetch(`${BACKEND_URL}/api/admin/${path}`, {
    method: 'GET',
    headers: {
      'X-Trace-Id': traceId,
      ...(token ? { 'Authorization': token } : {}),
    },
  })

  const data = await res.json()
  const response = NextResponse.json(data, { status: res.status })
  response.headers.set('X-Trace-Id', res.headers.get('X-Trace-Id') || traceId)
  return response
}

export async function PUT(request: NextRequest, context: { params: Promise<{ path: string[] }> }) {
  const params = await context.params
  const path = params.path.join('/')
  const body = await request.json()
  const token = request.headers.get('authorization')
  const traceId = request.headers.get('x-trace-id') || crypto.randomUUID()

  const res = await fetch(`${BACKEND_URL}/api/admin/${path}`, {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
      'X-Trace-Id': traceId,
      ...(token ? { 'Authorization': token } : {}),
    },
    body: JSON.stringify(body),
  })

  const data = await res.json()
  const response = NextResponse.json(data, { status: res.status })
  response.headers.set('X-Trace-Id', res.headers.get('X-Trace-Id') || traceId)
  return response
}

export async function DELETE(request: NextRequest, context: { params: Promise<{ path: string[] }> }) {
  const params = await context.params
  const path = params.path.join('/')
  const body = await request.json()
  const token = request.headers.get('authorization')
  const traceId = request.headers.get('x-trace-id') || crypto.randomUUID()

  const res = await fetch(`${BACKEND_URL}/api/admin/${path}`, {
    method: 'DELETE',
    headers: {
      'Content-Type': 'application/json',
      'X-Trace-Id': traceId,
      ...(token ? { 'Authorization': token } : {}),
    },
    body: JSON.stringify(body),
  })

  const data = await res.json()
  const response = NextResponse.json(data, { status: res.status })
  response.headers.set('X-Trace-Id', res.headers.get('X-Trace-Id') || traceId)
  return response
}
