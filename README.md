# Revisionary

Revision notes, exam questions and a teacher portal for A level PE (OCR).

## Run it
It is a single static page: `index.html`. Host it on GitHub Pages (Settings > Pages > Deploy from branch > main > /root).

## Turn on teacher/student accounts and set work
1. Create a free project at supabase.com.
2. Run `setup.sql` in the Supabase SQL Editor.
3. Authentication > Providers > Email: turn off "Confirm email".
4. In `index.html`, set `window.REV_CLOUD={url:"YOUR_PROJECT_URL",key:"YOUR_ANON_PUBLIC_KEY"}`.
   The anon key is designed to be public; the security rules in `setup.sql` protect the data.
   Never put the service_role key in this file.
