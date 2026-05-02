import os
import sys
import psycopg2
from dotenv import load_dotenv
from tabulate import tabulate
from datetime import datetime

load_dotenv()

def get_connection(prefix):
    return psycopg2.connect(
        host=os.getenv(f"{prefix}_HOST"),
        port=os.getenv(f"{prefix}_PORT", "5432"),
        dbname=os.getenv(f"{prefix}_DB"),
        user=os.getenv(f"{prefix}_USER"),
        password=os.getenv(f"{prefix}_PASSWORD")
    )

def run_query(conn, sql):
    with conn.cursor() as cur:
        cur.execute(sql)
        return cur.fetchall()

def check_row_counts(source, target):
    print("\n── Row Count Reconciliation ──────────────────────────")
    tables = ["customers", "products", "orders", "order_items"]
    results = []
    all_passed = True
    for table in tables:
        sql = f"SELECT COUNT(*) FROM {table}"
        source_count = run_query(source, sql)[0][0]
        target_count = run_query(target, sql)[0][0]
        match = source_count == target_count
        if not match:
            all_passed = False
        results.append([table, f"{source_count:,}", f"{target_count:,}",
                        "✅ PASS" if match else "❌ FAIL"])
    print(tabulate(results,
                   headers=["Table", "Source", "Target", "Result"],
                   tablefmt="rounded_outline"))
    return all_passed

def check_referential_integrity(target):
    print("\n── Referential Integrity ─────────────────────────────")
    checks = [
        ("orders → customers",
         "SELECT COUNT(*) FROM orders o LEFT JOIN customers c ON o.customer_id = c.customer_id WHERE c.customer_id IS NULL"),
        ("order_items → orders",
         "SELECT COUNT(*) FROM order_items oi LEFT JOIN orders o ON oi.order_id = o.order_id WHERE o.order_id IS NULL"),
        ("order_items → products",
         "SELECT COUNT(*) FROM order_items oi LEFT JOIN products p ON oi.product_id = p.product_id WHERE p.product_id IS NULL")
    ]
    results = []
    all_passed = True
    for label, sql in checks:
        orphan_count = run_query(target, sql)[0][0]
        passed = orphan_count == 0
        if not passed:
            all_passed = False
        results.append([label, orphan_count,
                        "✅ PASS" if passed else f"❌ FAIL ({orphan_count} orphans)"])
    print(tabulate(results,
                   headers=["Check", "Orphan Count", "Result"],
                   tablefmt="rounded_outline"))
    return all_passed

def check_order_totals(source, target):
    print("\n── Order Total Checksum ──────────────────────────────")
    sql = """
        SELECT
            ROUND(SUM(total_amount)::numeric, 2),
            ROUND(AVG(total_amount)::numeric, 2),
            MAX(total_amount),
            MIN(total_amount)
        FROM orders
    """
    source_result = run_query(source, sql)[0]
    target_result = run_query(target, sql)[0]
    labels = ["Grand Total", "Avg Order", "Max Order", "Min Order"]
    results = []
    all_passed = True
    for i, label in enumerate(labels):
        match = source_result[i] == target_result[i]
        if not match:
            all_passed = False
        results.append([label, f"{source_result[i]:,}", f"{target_result[i]:,}",
                        "✅ PASS" if match else "❌ FAIL"])
    print(tabulate(results,
                   headers=["Metric", "Source", "Target", "Result"],
                   tablefmt="rounded_outline"))
    return all_passed

def check_spot_sample(source, target):
    print("\n── Spot Sample Check (10 random customers) ──────────")
    sql = "SELECT customer_id, first_name, last_name, email FROM customers ORDER BY RANDOM() LIMIT 10"
    source_rows = run_query(source, sql)
    results = []
    all_passed = True
    for row in source_rows:
        customer_id = row[0]
        target_row = run_query(
            target,
            f"SELECT customer_id, first_name, last_name, email FROM customers WHERE customer_id = {customer_id}"
        )
        if not target_row:
            all_passed = False
            results.append([customer_id, "❌ NOT FOUND IN TARGET"])
            continue
        match = row == target_row[0]
        if not match:
            all_passed = False
        results.append([customer_id, "✅ MATCH" if match else "❌ MISMATCH"])
    print(tabulate(results, headers=["Customer ID", "Result"], tablefmt="rounded_outline"))
    return all_passed

def main():
    print("=" * 55)
    print("  Data Migration Validation Report")
    print(f"  {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 55)

    print("\nConnecting to source database...")
    source = get_connection("SOURCE")
    print("Connecting to target database...")
    target = get_connection("TARGET")

    results = {
        "Row Counts":            check_row_counts(source, target),
        "Referential Integrity": check_referential_integrity(target),
        "Order Totals":          check_order_totals(source, target),
        "Spot Sample":           check_spot_sample(source, target)
    }

    print("\n── Summary ───────────────────────────────────────────")
    summary = [[k, "✅ PASS" if v else "❌ FAIL"] for k, v in results.items()]
    print(tabulate(summary, headers=["Check", "Result"], tablefmt="rounded_outline"))

    source.close()
    target.close()

    all_passed = all(results.values())
    print(f"\n{'✅ ALL CHECKS PASSED' if all_passed else '❌ SOME CHECKS FAILED'}")
    print("=" * 55)
    sys.exit(0 if all_passed else 1)

if __name__ == "__main__":
    main()