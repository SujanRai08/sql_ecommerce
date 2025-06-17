"""
  Database creation for sql project.
all the entities were taken by example from the ecommerce website such as flipkart, amazon, daraz.
  For insertion we will likely use the py random formula and script file or using the mock data webiste..
"""

CREATE TABLE customer(
	customer_id SERIAL PRIMARY KEY,
	first_name VARCHAR(50) NOT NULL,
	last_name VARCHAR(50) NOT NULL,
	email VARCHAR(50) NOT NULL UNIQUE CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
	phone VARCHAR(50) UNIQUE CHECK (phone ~ '^[0-9+\-() ]{7,20}$'),
	city VARCHAR(50),
	state VARCHAR(50),
	country VARCHAR(50) NOT NULL,
	created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE categories(
	category_id SERIAL PRIMARY KEY,
	category_name VARCHAR(50) NOT NULL UNIQUE,
	description TEXT
);

--- products table
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    category_id INT NOT NULL,
    brand VARCHAR(50),
    unit_price DECIMAL(10, 2) NOT NULL CHECK (unit_price >= 0),
    stock_quantity INT NOT NULL CHECK (stock_quantity >= 0),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_category
      FOREIGN KEY (category_id)
      REFERENCES categories(category_id)
      ON DELETE SET NULL
);

-- orders
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL,
    order_date DATE NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('Completed', 'Pending', 'Cancelled')),
    shipping_fee DECIMAL(10, 2),
    payment_method VARCHAR(20) NOT NULL CHECK (payment_method IN ('Credit Card', 'COD', 'PayPal', 'Debit Card', 'Net Banking')),
    shipped_date DATE,
    CONSTRAINT fk_customer FOREIGN KEY (customer_id) REFERENCES customer(customer_id)
);

select count(*) FROM orders;

-- order items 
CREATE TABLE order_items(
	order_item_id SERIAL PRIMARY KEY,
	order_id INT NOT NULL,
	product_id INT NOT NULL,
	quantity INT NOT NULL CHECK (quantity > 0),
	unit_price DECIMAL(10,2)NOT NULL CHECK (unit_price >= 0),
	discount DECIMAL(5,2) NOT NULL DEFAULT 0 CHECK (discount >= 0 AND discount <= 100),
    subtotal DECIMAL(10, 2) NOT NULL CHECK (subtotal >= 0),

    CONSTRAINT fk_order
      FOREIGN KEY (order_id) REFERENCES orders(order_id)
      ON DELETE CASCADE,
    CONSTRAINT fk_product
      FOREIGN KEY (product_id) REFERENCES products(product_id)
      ON DELETE RESTRICT
);
