
import sqlite3
from pathlib import Path

DB_PATH = Path(__file__).resolve().parent / "collection_store.db"


def connect_db():
    connection = sqlite3.connect(DB_PATH)
    connection.row_factory = sqlite3.Row
    return connection


def create_tables():
    connection = connect_db()

    connection.execute("""
        CREATE TABLE IF NOT EXISTS products (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            category TEXT NOT NULL,
            description TEXT,
            price INTEGER NOT NULL,
            quantity INTEGER DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """)

    connection.commit()
    connection.close()


if __name__ == "__main__":
    create_tables()
    print("Database created successfully!")


def add_product(name, category, description, price, quantity):
    connection = connect_db()

    connection.execute("""
        INSERT INTO products
        (name, category, description, price, quantity)
        VALUES (?, ?, ?, ?, ?)
    """, (name, category, description, price, quantity))

    connection.commit()
    connection.close()

    print("Product added successfully!")


if __name__ == "__main__":
    create_tables()

    add_product(
        "سکه یادبود",
        "سکه",
        "سکه کلکسیونی قدیمی",
        500000,
        2
    )

    print("Database is ready!")


def get_products():
    connection = connect_db()

    products = connection.execute(
        "SELECT * FROM products"
    ).fetchall()

    connection.close()

    return [dict(product) for product in products]



if __name__ == "__main__":
    create_tables()

    products = get_products()

    print("\n--- Collection Store Products ---")

    for product in products:
        print("ID:", product["id"])
        print("Name:", product["name"])
        print("Category:", product["category"])
        print("Price:", product["price"])
        print("Quantity:", product["quantity"])
        print("----------------------")
        

# ویرایش محصول
def update_product(product_id, name, category, description, price, quantity):
    connection = connect_db()

    cursor = connection.execute("""
        UPDATE products
        SET name = ?, category = ?, description = ?,
            price = ?, quantity = ?
        WHERE id = ?
    """, (name, category, description, price, quantity, product_id))

    connection.commit()
    updated = cursor.rowcount > 0
    connection.close()

    return updated


# حذف محصول
def delete_product(product_id):
    connection = connect_db()

    cursor = connection.execute(
        "DELETE FROM products WHERE id = ?",
        (product_id,)
    )

    connection.commit()
    deleted = cursor.rowcount > 0
    connection.close()

    return deleted


