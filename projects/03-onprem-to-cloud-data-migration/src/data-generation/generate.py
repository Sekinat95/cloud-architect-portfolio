import os
import psycopg2
from faker import Faker
from dotenv import load_dotenv
import random
from decimal import Decimal

load_dotenv()

fake = Faker()

conn = psycopg2.connect(
    host=os.getenv("DB_HOST"),
    port=os.getenv("DB_PORT", "5432"),
    dbname=os.getenv("DB_NAME", "retail_db"),
    user=os.getenv("DB_USER", "migration_user"),
    password=os.getenv("DB_PASSWORD")
)

cursor = conn.cursor()

# Apply schema
print("Applying schema...")
with open("schema.sql", "r") as f:
    cursor.execute(f.read())
conn.commit()

# Generate customers
print("Generating customers...")
CUSTOMER_COUNT = 10000
customers = []
for _ in range(CUSTOMER_COUNT):
    customers.append((
    fake.first_name()[:50],
    fake.last_name()[:50],
    fake.unique.email()[:100],
    fake.phone_number()[:20],
    fake.street_address()[:200],
    fake.city()[:50],
    fake.country()[:50]
))
cursor.executemany("""
    INSERT INTO customers
    (first_name, last_name, email, phone, address, city, country)
    VALUES (%s, %s, %s, %s, %s, %s, %s)
""", customers)
conn.commit()
print(f"Inserted {CUSTOMER_COUNT} customers")

# Generate products
print("Generating products...")
PRODUCT_COUNT = 5000
categories = ['Electronics', 'Clothing', 'Food', 'Books', 'Home', 'Sports', 'Toys']
products = []
for _ in range(PRODUCT_COUNT):
    products.append((
        fake.unique.catch_phrase()[:100],
        random.choice(categories),
        round(random.uniform(1.99, 999.99), 2),
        random.randint(0, 500)
    ))
cursor.executemany("""
    INSERT INTO products
    (product_name, category, price, stock_quantity)
    VALUES (%s, %s, %s, %s)
""", products)
conn.commit()
print(f"Inserted {PRODUCT_COUNT} products")

# Generate orders in batches
print("Generating orders...")
ORDER_COUNT = 50000
statuses = ['pending', 'processing', 'shipped', 'delivered', 'cancelled']
order_ids = []
for i in range(0, ORDER_COUNT, 1000):
    for _ in range(min(1000, ORDER_COUNT - i)):
        cursor.execute("""
            INSERT INTO orders (customer_id, order_date, status, total_amount)
            VALUES (%s, %s, %s, %s)
            RETURNING order_id
        """, (
            random.randint(1, CUSTOMER_COUNT),
            fake.date_time_between(start_date='-2y', end_date='now'),
            random.choice(statuses),
            0
        ))
        order_ids.append(cursor.fetchone()[0])
    conn.commit()
    print(f"  Orders batch {i+1000}/{ORDER_COUNT}")
# Generate order items
print("Generating order items...")
order_items = []
order_totals = {oid: Decimal('0.00') for oid in order_ids}
for order_id in order_ids:
    item_count = random.randint(1, 8)
    used_products = set()
    for _ in range(item_count):
        product_id = random.randint(1, PRODUCT_COUNT)
        while product_id in used_products:
            product_id = random.randint(1, PRODUCT_COUNT)
        used_products.add(product_id)
        quantity = random.randint(1, 5)
        unit_price = round(random.uniform(1.99, 999.99), 2)
        order_totals[order_id] += Decimal(str(unit_price)) * quantity
        order_items.append((order_id, product_id, quantity, unit_price))

# Insert order items in batches
print("Inserting order items...")
BATCH_SIZE = 5000
for i in range(0, len(order_items), BATCH_SIZE):
    batch = order_items[i:i+BATCH_SIZE]
    cursor.executemany("""
        INSERT INTO order_items (order_id, product_id, quantity, unit_price)
        VALUES (%s, %s, %s, %s)
    """, batch)
    conn.commit()
    print(f"  Order items {i+BATCH_SIZE}/{len(order_items)}")

# Update order totals
print("Updating order totals...")
for order_id, total in order_totals.items():
    cursor.execute(
        "UPDATE orders SET total_amount = %s WHERE order_id = %s",
        (total, order_id)
    )
conn.commit()

# Summary
cursor.execute("SELECT COUNT(*) FROM customers")
print(f"\nFinal counts:")
print(f"  Customers:   {cursor.fetchone()[0]:,}")
cursor.execute("SELECT COUNT(*) FROM products")
print(f"  Products:    {cursor.fetchone()[0]:,}")
cursor.execute("SELECT COUNT(*) FROM orders")
print(f"  Orders:      {cursor.fetchone()[0]:,}")
cursor.execute("SELECT COUNT(*) FROM order_items")
print(f"  Order items: {cursor.fetchone()[0]:,}")

cursor.close()
conn.close()
print("\nData generation complete.")
