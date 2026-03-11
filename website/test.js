const { createClient } = require('@supabase/supabase-js');
const supabaseUrl = 'https://phxazbsbnglpjnauhxah.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBoeGF6YnNibmdscGpuYXVoeGFoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIzNjYwNDQsImV4cCI6MjA4Nzk0MjA0NH0.7mrMb6OnPIiShYZqOexiRcWbeLghAKtdncVhbIVRyA8';
const supabase = createClient(supabaseUrl, supabaseKey);

async function test() {
  const { data: initialData, error: initialError } = await supabase.rpc('get_app_metrics');
  console.log('Initial data:', initialData, initialError);
  
  const { error: incError } = await supabase.rpc('increment_downloads');
  console.log('Increment result error:', incError);
  
  const { data: finalData, error: finalError } = await supabase.rpc('get_app_metrics');
  console.log('Final data:', finalData, finalError);
}

test();
