package com.securevault.app

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity

/**
 * MainActivity for SecureVault.
 *
 * Security measures applied here:
 *
 *  1. FLAG_SECURE – prevents screenshots and screen recording.
 *     Also replaces the app thumbnail in the Android task switcher
 *     with a blank/black frame, hiding vault content.
 *
 *  2. FlutterFragmentActivity is used (instead of FlutterActivity)
 *     because local_auth requires the FragmentActivity lifecycle
 *     for biometric prompt support on all Android versions.
 */
class MainActivity : FlutterFragmentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // ── Screenshot / screen-recording prevention ──────────────────────
        // FLAG_SECURE makes this window opaque to screen capture APIs and
        // replaces the recent-apps thumbnail with a blank screen.
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
    }

    override fun onResume() {
        super.onResume()
        // Re-apply FLAG_SECURE on resume in case it was cleared
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
    }
}
