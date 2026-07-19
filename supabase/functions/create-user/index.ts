// Supabase Edge Function: create-user
//
// Purpose: Allows authenticated Supervisors to provision new user accounts safely.
// Public signup is disabled (Doc 16 — Identity & Auth §3).
//
// Security Requirements:
// 1. Verifies caller's Authorization JWT token.
// 2. Confirms caller has the 'supervisor' role in public.users.
// 3. Uses Supabase Service Role client to create Auth user and insert public.users profile.
// 4. Rollback: If profile creation fails, deletes the newly created Auth user.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface CreateUserRequestBody {
  email: string;
  password: string;
  name: string;
  role: "supervisor" | "foreman" | "crew";
  site_id?: string;
  phone?: string;
  national_id?: string;
  birthdate?: string;
  gender?: string;
  emergency_contact_name?: string;
  emergency_contact_phone?: string;
}

Deno.serve(async (req: Request) => {
  // Handle CORS preflight request
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing Authorization header" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    if (!supabaseUrl || !supabaseServiceRoleKey) {
      return new Response(
        JSON.stringify({ error: "Server configuration missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 1. Verify caller identity using caller's JWT token
    const token = authHeader.replace("Bearer ", "");
    const callerClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: { user: callerUser }, error: callerUserError } = await callerClient.auth.getUser(token);
    if (callerUserError || !callerUser) {
      return new Response(
        JSON.stringify({ error: "Invalid or expired token" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 2. Admin client with Service Role privileges
    const adminClient = createClient(supabaseUrl, supabaseServiceRoleKey);

    // 3. Verify caller role is supervisor in public.users
    const { data: callerProfile, error: callerProfileError } = await adminClient
      .from("users")
      .select("role, is_active, deleted_at")
      .eq("id", callerUser.id)
      .single();

    if (
      callerProfileError ||
      !callerProfile ||
      callerProfile.role !== "supervisor" ||
      !callerProfile.is_active ||
      callerProfile.deleted_at !== null
    ) {
      return new Response(
        JSON.stringify({ error: "Forbidden. Only active supervisors can create user accounts." }),
        { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 4. Parse & validate request body
    const body: CreateUserRequestBody = await req.json();
    const {
      email,
      password,
      name,
      role,
      site_id = "00000000-0000-0000-0000-000000000001",
      phone,
      national_id,
      birthdate,
      gender,
      emergency_contact_name,
      emergency_contact_phone,
    } = body;

    if (!email || !password || !name || !role) {
      return new Response(
        JSON.stringify({ error: "Missing required fields: email, password, name, and role are required." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (!["supervisor", "foreman", "crew"].includes(role)) {
      return new Response(
        JSON.stringify({ error: "Invalid role. Must be 'supervisor', 'foreman', or 'crew'." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 5. Create Auth user via Admin API
    const { data: newAuthUser, error: createAuthError } = await adminClient.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: { name, role },
    });

    if (createAuthError || !newAuthUser.user) {
      return new Response(
        JSON.stringify({ error: createAuthError?.message || "Failed to create Auth user" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const userId = newAuthUser.user.id;

    // 6. Insert corresponding profile into public.users table
    const { data: userProfile, error: profileInsertError } = await adminClient
      .from("users")
      .insert({
        id: userId,
        email,
        name,
        role,
        site_id,
        phone,
        national_id,
        birthdate,
        gender,
        emergency_contact_name,
        emergency_contact_phone,
        is_active: true,
      })
      .select()
      .single();

    if (profileInsertError) {
      // Rollback Auth user creation if profile insert fails
      await adminClient.auth.admin.deleteUser(userId);
      return new Response(
        JSON.stringify({ error: `Failed to insert user profile: ${profileInsertError.message}` }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 7. Success response
    return new Response(
      JSON.stringify({ message: "User account created successfully", user: userProfile }),
      { status: 201, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err: any) {
    return new Response(
      JSON.stringify({ error: err.message || "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
