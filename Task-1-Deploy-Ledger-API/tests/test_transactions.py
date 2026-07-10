import importlib
import os
import tempfile
import unittest


class TransactionsStoreTests(unittest.TestCase):
    def setUp(self):
        self.db_file = tempfile.NamedTemporaryFile(delete=False).name
        os.environ["DATABASE_PATH"] = self.db_file
        import app.app as app_module

        importlib.reload(app_module)
        self.client = app_module.app.test_client()

    def tearDown(self):
        if os.path.exists(self.db_file):
            os.remove(self.db_file)

    def test_create_and_list_transactions_without_pan(self):
        response = self.client.post(
            "/transactions",
            json={
                "token": "tok_test_123",
                "last4": "4242",
                "amount": 49.99,
                "currency": "USD",
                "status": "pending",
            },
        )

        self.assertEqual(response.status_code, 201)
        payload = response.get_json()
        self.assertEqual(payload["token"], "tok_test_123")
        self.assertEqual(payload["status"], "pending")

        list_response = self.client.get("/transactions")
        self.assertEqual(list_response.status_code, 200)
        rows = list_response.get_json()
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0]["token"], "tok_test_123")

    def test_rejects_pan_values(self):
        response = self.client.post(
            "/transactions",
            json={"pan": "4111111111111111", "amount": 10, "currency": "USD", "status": "pending"},
        )

        self.assertEqual(response.status_code, 400)
        self.assertIn("raw card numbers", response.get_json()["error"])


if __name__ == "__main__":
    unittest.main()
