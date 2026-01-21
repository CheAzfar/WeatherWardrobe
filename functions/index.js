const { onRequest } = require("firebase-functions/v2/https");
const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
const stripe = require("stripe")('sk_test_51SrHwI3uzkOxb9efK4EIz3zy0Mvhd3ECgGKHUtUB1pFzM9ucPm5ZyPuT4QS0xYMzde06URKymU8ESjEjesokzdmS00RQzomKl4');

admin.initializeApp();

// ---------------------------------------------------------
// Function 1: Stripe Payment Intent (HTTPS Request)
// ---------------------------------------------------------
exports.createPaymentIntent = onRequest(async (req, res) => {
  // Enable CORS manually
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  try {
    const { amount, currency } = req.body;
    if (!amount || !currency) {
      res.status(400).json({ error: 'Missing amount or currency' });
      return;
    }

    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(amount),
      currency: currency,
      automatic_payment_methods: { enabled: true },
    });

    res.json({
      clientSecret: paymentIntent.client_secret,
      paymentIntentId: paymentIntent.id,
    });
  } catch (error) {
    console.error('Stripe error:', error);
    res.status(500).json({ error: error.message });
  }
});

// ---------------------------------------------------------
// Function 2: Send Notification on Sale (Firestore Trigger)
// ---------------------------------------------------------
exports.sendSaleNotification = onDocumentUpdated("marketplace_listings/{listingId}", async (event) => {
    // In v2, data is inside event.data
    const newData = event.data.after.data();
    const oldData = event.data.before.data();

    // 1. Check if status changed to 'sold'
    if (newData.status === 'sold' && oldData.status !== 'sold') {
      const sellerId = newData.sellerId;
      const itemName = newData.title || 'Item';

      console.log(`Item ${itemName} sold! Notifying seller ${sellerId}...`);

      try {
        // 2. Get Seller Token
        const sellerDoc = await admin.firestore().collection('users').doc(sellerId).get();
        if (!sellerDoc.exists) {
            console.log("Seller not found");
            return;
        }

        // 3. Save Notification to Firestore History
        await admin.firestore()
          .collection('users')
          .doc(sellerId)
          .collection('notifications')
          .add({
            title: 'Item Sold! 💰',
            body: `Your item "${itemName}" has been purchased.`,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            read: false
          });

        // 4. Send Push Notification
        const token = sellerDoc.data().fcmToken;
        if (token) {
            const payload = {
                notification: {
                    title: 'Cha-ching! Item Sold 💰',
                    body: `Someone just bought your "${itemName}"! Check your sales.`
                },
                data: { click_action: 'FLUTTER_NOTIFICATION_CLICK' }
            };
            await admin.messaging().sendToDevice(token, payload);
        }
      } catch (error) {
        console.error("Error processing sale notification:", error);
      }
    }
});