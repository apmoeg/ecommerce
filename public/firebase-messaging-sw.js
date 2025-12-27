importScripts('https://www.gstatic.com/firebasejs/8.3.2/firebase-app.js');
importScripts('https://www.gstatic.com/firebasejs/8.3.2/firebase-messaging.js');
importScripts('https://www.gstatic.com/firebasejs/8.3.2/firebase-auth.js');

firebase.initializeApp({
    apiKey: "AIzaSyDSLsHfSK7mDJI5QsYOZSyGt0dpOzVZ1oM",
    authDomain: "no1or-cdd72.firebaseapp.com",
    projectId: "no1or-cdd72",
    storageBucket: "no1or-cdd72.firebasestorage.app",
    messagingSenderId: "343401628573",
    appId: "1:343401628573:web:4152c2b245e50a4e622574",
    measurementId: "G-51XYEKW26Q"
});

const messaging = firebase.messaging();
messaging.setBackgroundMessageHandler(function(payload) {
    return self.registration.showNotification(payload.data.title, {
        body: payload.data.body || '',
        icon: payload.data.icon || ''
    });
});