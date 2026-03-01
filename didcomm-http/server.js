const express = require("express");
const { Message } = require("didcomm-node");

const app = express();
app.use(express.json({ limit: "1mb" }));

// --- Stateless resolvers: created per-request from caller-provided data ---

function createDIDResolver(didDocs) {
  return {
    resolve: async (did) =>
      (didDocs || []).find((d) => d.id === did) || null,
  };
}

function createSecretsResolver(secrets) {
  return {
    get_secret: async (id) =>
      (secrets || []).find((s) => s.id === id) || null,
    find_secrets: async (ids) =>
      ids.filter((id) => (secrets || []).find((s) => s.id === id)),
  };
}

// --- Endpoints ---

app.get("/health", (_req, res) => {
  res.json({ status: "ok" });
});

app.post("/pack/encrypted", async (req, res, next) => {
  try {
    const { message, to, from, sign_by, did_docs, secrets, options } = req.body;
    const msg = new Message(message);
    const [packed, metadata] = await msg.pack_encrypted(
      to,
      from || null,
      sign_by || null,
      createDIDResolver(did_docs),
      createSecretsResolver(secrets),
      options || {}
    );
    res.json({ packed_message: packed, metadata });
  } catch (err) {
    next(err);
  }
});

app.post("/pack/signed", async (req, res, next) => {
  try {
    const { message, sign_by, did_docs, secrets } = req.body;
    const msg = new Message(message);
    const [packed, metadata] = await msg.pack_signed(
      sign_by,
      createDIDResolver(did_docs),
      createSecretsResolver(secrets)
    );
    res.json({ packed_message: packed, metadata });
  } catch (err) {
    next(err);
  }
});

app.post("/pack/plaintext", async (req, res, next) => {
  try {
    const { message, did_docs } = req.body;
    const msg = new Message(message);
    const packed = await msg.pack_plaintext(createDIDResolver(did_docs));
    res.json({ packed_message: packed });
  } catch (err) {
    next(err);
  }
});

app.post("/unpack", async (req, res, next) => {
  try {
    const { packed_message, did_docs, secrets, options } = req.body;
    const [msg, metadata] = await Message.unpack(
      packed_message,
      createDIDResolver(did_docs),
      createSecretsResolver(secrets),
      options || {}
    );
    res.json({ message: msg.as_value(), metadata });
  } catch (err) {
    next(err);
  }
});

app.post("/forward/wrap", async (req, res, next) => {
  try {
    const { packed_message, headers, to, routing_keys, enc_alg_anon, did_docs } = req.body;
    const packed = await Message.wrap_in_forward(
      packed_message,
      headers || {},
      to,
      routing_keys,
      enc_alg_anon || "A256cbcHs512EcdhEsA256kw",
      createDIDResolver(did_docs)
    );
    res.json({ packed_message: packed });
  } catch (err) {
    next(err);
  }
});

// --- Error handler ---

app.use((err, _req, res, _next) => {
  console.error(err);
  res.status(400).json({ error: err.message || String(err) });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`DIDComm HTTP service listening on port ${PORT}`);
});
