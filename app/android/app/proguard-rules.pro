# Stripe push provisioning - prevent R8 missing class error
-keep class com.stripe.android.pushProvisioning.** { *; }
-dontwarn com.stripe.android.pushProvisioning.**
