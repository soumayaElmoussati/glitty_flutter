package com.example.glitty;

import io.flutter.Log;
import com.google.firebase.messaging.FirebaseMessagingService;
import com.google.firebase.messaging.RemoteMessage;
import androidx.core.app.NotificationCompat;
import androidx.core.app.NotificationManagerCompat;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.os.Build;
import android.app.PendingIntent;
import android.content.Intent;
import androidx.localbroadcastmanager.content.LocalBroadcastManager;
import android.content.Context;

public class MyFirebaseMessagingService extends FirebaseMessagingService {
    private static final String TAG = "FCMService";
    private static final String CHANNEL_ID = "high_importance_channel";

    @Override
    public void onNewToken(String token) {
        Log.d(TAG, "Refreshed token: " + token);
        // Envoyer le token à votre serveur ou le gérer dans Flutter
    }

    @Override
    public void onMessageReceived(RemoteMessage remoteMessage) {
        Log.d(TAG, "From: " + remoteMessage.getFrom());

        // Vérifier si le message contient une notification
        if (remoteMessage.getNotification() != null) {
            Log.d(TAG, "Message Notification Body: " + remoteMessage.getNotification().getBody());
            showNotification(
                remoteMessage.getNotification().getTitle(),
                remoteMessage.getNotification().getBody(),
                remoteMessage.getData()
            );
        }

        // Émettre un broadcast pour Flutter
        sendMessageToFlutter(remoteMessage);
    }

    private void showNotification(String title, String messageBody, java.util.Map<String, String> data) {
        createNotificationChannel();

        Intent intent = new Intent(this, MainActivity.class);
        intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
        PendingIntent pendingIntent = PendingIntent.getActivity(this, 0, intent,
            PendingIntent.FLAG_ONE_SHOT | PendingIntent.FLAG_IMMUTABLE);

        NotificationCompat.Builder notificationBuilder = new NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info) // Utilisez votre propre icône
            .setContentTitle(title != null ? title : "Nouvelle commande")
            .setContentText(messageBody != null ? messageBody : "Vous avez une nouvelle commande")
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setDefaults(NotificationCompat.DEFAULT_ALL);

        NotificationManagerCompat notificationManager = NotificationManagerCompat.from(this);
        notificationManager.notify((int) System.currentTimeMillis(), notificationBuilder.build());
    }

    private void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            CharSequence name = "Notifications importantes";
            String description = "Ce canal est utilisé pour les notifications importantes";
            int importance = NotificationManager.IMPORTANCE_HIGH;
            NotificationChannel channel = new NotificationChannel(CHANNEL_ID, name, importance);
            channel.setDescription(description);
            
            NotificationManager notificationManager = getSystemService(NotificationManager.class);
            notificationManager.createNotificationChannel(channel);
        }
    }

    private void sendMessageToFlutter(RemoteMessage remoteMessage) {
        Intent intent = new Intent("fcm_message");
        intent.putExtra("title", remoteMessage.getNotification() != null ? 
            remoteMessage.getNotification().getTitle() : "");
        intent.putExtra("body", remoteMessage.getNotification() != null ? 
            remoteMessage.getNotification().getBody() : "");
        intent.putExtra("data", new java.util.HashMap<>(remoteMessage.getData()));
        
        LocalBroadcastManager.getInstance(this).sendBroadcast(intent);
    }
}