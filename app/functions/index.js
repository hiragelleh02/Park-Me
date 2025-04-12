const { onCall } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const stripe = require("stripe")("sk_test_51RAbmOP5MNSclPDpgvKNknrrlYV3UgmODsDKWJNR3Niq9fHc409ELULQlavh4Ds386noG6MEO4JRZXmsY8iZfSef00B4agW7EQ");

initializeApp();
const db = getFirestore();

exports.createStripePayment = onCall(async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
        throw new Error("UNAUTHENTICATED: No user is signed in.");
    }

    const userDoc = await db.collection("users").doc(uid).get();
    if (!userDoc.exists) {
        throw new Error("UNAUTHORIZED: User not found in database.");
    }

    const amount = request.data.amount;
    const currency = request.data.currency || "usd";

    if (!amount || amount < 50) {
        throw new Error("Invalid payment amount.");
    }

    const paymentIntent = await stripe.paymentIntents.create({
        amount,
        currency,
        metadata: {
            uid: uid,
        },
    });

    return {
        clientSecret: paymentIntent.client_secret,
    };
});
