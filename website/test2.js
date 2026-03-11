const { createClient } = require('@supabase/supabase-js');
const supabaseUrl = 'https://phxazbsbnglpjnauhxah.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBoeGF6YnNibmdscGpuYXVoeGFoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIzNjYwNDQsImV4cCI6MjA4Nzk0MjA0NH0.7mrMb6OnPIiShYZqOexiRcWbeLghAKtdncVhbIVRyA8';
const supabase = createClient(supabaseUrl, supabaseKey);

async function check() {
  const { data, error } = await supabase.from('app_metrics').select('*');
  console.log('Table data:', data, error);
}

check();
