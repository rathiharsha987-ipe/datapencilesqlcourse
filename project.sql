CREATE DATABASE food_app_project;

USE food_app_project;

--1 CREATE table customer where columns are customer_id,name,city,signup_date,gender

CREATE TABLE customer (
    customer_id INT PRIMARY KEY,
    name VARCHAR(100),
    city VARCHAR(100),
    signup_date DATE,
    gender VARCHAR(10)
);

--2 CREATE table restaurant where columns are restaurant_id,restaurant_name,city,cuisine,rating

CREATE TABLE restaurant (
    restaurant_id INT PRIMARY KEY,
    restaurant_name VARCHAR(100),
    city VARCHAR(100),
    cuisine VARCHAR(50),
    rating DECIMAL(3,2)
);

--3 create table delivery_agent where columns are agent_id,agent_name,city,joining_date,rating

CREATE TABLE delivery_agent (
    agent_id INT PRIMARY KEY,
    agent_name VARCHAR(100),
    city VARCHAR(100),
    joining_date DATE,
    rating DECIMAL(3,2)
);

--4 create table orders where columns are order_id,customer_id,restaurant_id,order_date,order_amount,discount,payment_method,delivery_time

CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    restaurant_id INT,
    order_date DATE,
    order_amount DECIMAL(10,2),
    discount DECIMAL(5,2),
    payment_method VARCHAR(50),
    delivery_time TIME,
    FOREIGN KEY (customer_id) REFERENCES customer(customer_id),
    FOREIGN KEY (restaurant_id) REFERENCES restaurant(restaurant_id)
);

--5 create table order_items where columns are order_item_id,order_id,item_name,quantity,price

CREATE TABLE order_items (
    order_item_id INT PRIMARY KEY,
    order_id INT,
    item_name VARCHAR(100),
    quantity INT,
    price DECIMAL(10,2),
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);
