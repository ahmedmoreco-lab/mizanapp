async function startApp() {
  try {
    const [core, auth, firestore] = await Promise.all([
      import('./firebase/firebase-app.js'),
      import('./firebase/firebase-auth.js'),
      import('./firebase/firebase-firestore.js'),
    ]);

    window.firebase_core = core;
    window.firebase_auth = auth;
    window.firebase_firestore = firestore;

    const flutter = document.createElement('script');
    flutter.src = 'flutter_bootstrap.js';
    flutter.async = true;
    flutter.addEventListener('error', showLoadError);
    document.body.appendChild(flutter);
  } catch (error) {
    console.error('Firebase startup failed', error);
    showLoadError();
  }
}

function showLoadError() {
  document.body.replaceChildren();

  const main = document.createElement('main');
  main.className = 'load-error';

  const title = document.createElement('h1');
  title.textContent = 'Could not load Ahmed OS';

  const message = document.createElement('p');
  message.textContent = 'Reconnect, then try again.';

  const retry = document.createElement('button');
  retry.type = 'button';
  retry.textContent = 'Retry';
  retry.addEventListener('click', () => window.location.reload());

  main.append(title, message, retry);
  document.body.appendChild(main);
}

startApp();
