
// ==============================================================================
// SUPABASE EDGE FUNCTION: push-notification
// ==============================================================================
// Deploy this function to Supabase:
// supabase functions deploy push-notification --no-verify-jwt
//
// Required Secrets in Supabase Dashboard (Edge Functions > Secrets):
// - FIREBASE_SERVICE_ACCOUNT (We will just use the file approach for simplicity if user ignores secrets)
//
// BUT, to keep it simple for the user, we are assuming they will drop the 'service-account.json' 
// right next to this file.

import { createClient } from 'jsr:@supabase/supabase-js@2'
import { JWT } from 'npm:google-auth-library'
import serviceAccount from './service-account.json' with { type: 'json' }

// Note: You must place your firebase-service-account.json in the same folder 
// and rename it to 'service-account.json'
// OR update the import above.

const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
)

Deno.serve(async (req) => {
    const payload = await req.json()

    // Expecting payload from Database Webhook or direct call
    // { record: { user_id: "...", title: "...", body: "..." } }

    console.log('Received payload:', payload)

    const record = payload.record
    if (!record) {
        return new Response('No record provided', { status: 400 })
    }

    const userId = record.user_id

    // 1. Get User's FCM Tokens (from the table we created)
    const { data: tokens, error } = await supabase
        .from('user_fcm_tokens')
        .select('token')
        .eq('user_id', userId)

    if (error || !tokens || tokens.length === 0) {
        console.log('No tokens found for user', userId)
        return new Response('No tokens found', { status: 200 })
    }

    // 2. Get Access Token for Firebase
    const jwtClient = new JWT({
        email: serviceAccount.client_email,
        key: serviceAccount.private_key,
        scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
    })

    const tokensInfo = await jwtClient.authorize()
    const accessToken = tokensInfo.access_token

    // 3. Send Notifications
    const promises = tokens.map(async (t) => {
        const fcmMessage = {
            message: {
                token: t.token,
                notification: {
                    title: record.title,
                    body: record.body,
                },
                data: record.data || {},
            },
        }

        const res = await fetch(
            `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`,
            {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    Authorization: `Bearer ${accessToken}`,
                },
                body: JSON.stringify(fcmMessage),
            }
        )
        return res.json()
    })

    const results = await Promise.all(promises)

    return new Response(
        JSON.stringify({ success: true, results }),
        { headers: { 'Content-Type': 'application/json' } }
    )
})
