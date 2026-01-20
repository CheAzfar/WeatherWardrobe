const functions = require('firebase-functions');
const stripe = require('stripe')('sk_test_51SrHwI3uzkOxb9efK4EIz3zy0Mvhd3ECgGKHUtUB1pFzM9ucPm5ZyPuT4QS0xYMzde06URKymU8ESjEjesokzdmS00RQzomKl4');

exports.createPaymentIntent = functions.https.onRequest(async (req, res) => {
  // Enable CORS
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'POST');
  res.set('Access-Control-Allow-Headers', 'Content-Type');

  // Handle preflight
  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }

  try {
    const { amount, currency } = req.body;

    // Validate
    if (!amount || !currency) {
      res.status(400).json({ error: 'Missing amount or currency' });
      return;
    }

    // Create PaymentIntent
    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(amount),
      currency: currency,
      automatic_payment_methods: {
        enabled: true,
      },
    });

    // Return to app
    res.json({
      clientSecret: paymentIntent.client_secret,
      paymentIntentId: paymentIntent.id,
    });
  } catch (error) {
    console.error('Stripe error:', error);
    res.status(500).json({ error: error.message });
  }
});