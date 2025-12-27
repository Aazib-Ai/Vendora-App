import '../models/product_model.dart';
import '../models/user_model.dart';
import '../models/order_model.dart';
import '../models/seller_model.dart';
import '../models/admin_model.dart';

// Demo Products
final List<Product> demoProducts = [
  Product(
    id: '1',
    name: 'Antique Diamond Ring',
    category: 'Jewellery',
    description: 'Beautiful antique diamond ring with exquisite craftsmanship.',
    price: 150000,
    imageUrl: 'assets/images/ring.png',
    rating: 5.0,
    reviewCount: 12,
    specifications: {
      'size': '5',
      'color': 'silver',
      'Quality': 'A+',
    },
    sellerId: 'seller1',
    status: 'approved',
  ),
  Product(
    id: '2',
    name: 'Modern light clothes',
    category: 'Clothing',
    description: 'Comfortable and stylish modern clothing.',
    price: 4500,
    imageUrl: 'assets/images/clothes.png',
    rating: 5.0,
    reviewCount: 8,
    specifications: {
      'size': 'M',
      'color': 'Light',
      'Material': 'Cotton',
    },
    sellerId: 'seller2',
    status: 'approved',
  ),
  Product(
    id: '3',
    name: 'Harry Potter Series II',
    category: 'Books',
    description: 'Harry Potter and the Cursed Child is a play written by Jack Thorne from an original story by Thorne, J. K. Rowling, and John Tiffany.',
    price: 4500,
    imageUrl: 'assets/images/book.png',
    rating: 4.5,
    reviewCount: 25,
    specifications: {
      'Author': 'J.K. Rowling',
      'Pages': '320',
      'Language': 'English',
    },
    sellerId: 'seller1',
    status: 'approved',
  ),
  Product(
    id: '4',
    name: 'Light Dress Bless',
    category: 'Clothing',
    description: 'Elegant light dress perfect for any occasion.',
    price: 4500,
    imageUrl: 'assets/images/dress.png',
    rating: 5.0,
    reviewCount: 15,
    specifications: {
      'size': 'S',
      'color': 'Pink',
      'Material': 'Silk',
    },
    sellerId: 'seller2',
    status: 'pending',
  ),
];

// Demo Users
final List<User> demoUsers = [
  User(
    id: 'user1',
    name: 'Aryan Mirza',
    email: 'aryanmirza1122@gmail.com',
    phone: '+92 304 0974326',
    address: 'Street 15, Model Town',
    role: 'buyer',
    profileImageUrl: 'assets/images/profile.png',
  ),
  User(
    id: 'user2',
    name: 'Ali Khan',
    email: 'ali@mail.com',
    phone: '+92 300 1234567',
    address: 'Street 20, Gulberg',
    role: 'buyer',
  ),
];

// Demo Sellers
final List<Seller> demoSellers = [
  Seller(
    id: 'seller1',
    name: 'Aryan Mirza',
    email: 'zeesheir420@gmail.com',
    businessCategory: 'Jewellery',
    address: 'Street 15, Model Town',
    profileImageUrl: 'assets/images/profile.png',
    status: 'pending',
    totalProducts: 5,
    totalSales: 250000.0,
  ),
  Seller(
    id: 'seller2',
    name: 'Ali Khan',
    email: 'ali@mail.com',
    businessCategory: 'Clothing',
    address: 'Street 20, Gulberg',
    status: 'approved',
    totalProducts: 12,
    totalSales: 500000.0,
  ),
];

// Demo Admins
final List<Admin> demoAdmins = [
  Admin(
    id: 'admin1',
    name: 'Aryan Mirza',
    email: 'aryanmirza1122@gmail.com',
    password: '*********',
    role: 'admin',
    profileImageUrl: 'assets/images/profile.png',
  ),
  Admin(
    id: 'admin2',
    name: 'Ali Khan',
    email: 'aryan@mail.com',
    password: '*********',
    role: 'admin',
  ),
];

// Demo Orders
final List<Order> demoOrders = [
  Order(
    id: 'order1',
    userId: 'user1',
    items: [
      OrderItem(
        productId: '2',
        productName: 'Modern light clothes',
        quantity: 1,
        price: 4500,
      ),
      OrderItem(
        productId: '1',
        productName: 'Antique Diamond Ring',
        quantity: 1,
        price: 150000,
      ),
    ],
    subtotal: 154500,
    total: 154500,
    status: 'completed',
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
    shippingInfo: ShippingInfo(
      name: 'Aryan Ijaz',
      address: 'Street 15, Model Town',
      phone: '+92 304 0974326',
    ),
    paymentInfo: PaymentInfo(
      method: 'visa',
      maskedNumber: '**** **** **** 2143',
    ),
  ),
  Order(
    id: 'order2',
    userId: 'user1',
    items: [
      OrderItem(
        productId: '3',
        productName: 'Harry Potter Series II',
        quantity: 1,
        price: 4500,
      ),
    ],
    subtotal: 4500,
    total: 4500,
    status: 'pending',
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    shippingInfo: ShippingInfo(
      name: 'Aryan Ijaz',
      address: 'Street 15, Model Town',
      phone: '+92 304 0974326',
    ),
    paymentInfo: PaymentInfo(
      method: 'jazzcash',
      maskedNumber: '**** **** **** 1345',
    ),
  ),
];

// Help Center Topics
final List<Map<String, String>> helpTopics = [
  {
    'question': 'How to reset password?',
    'answer': 'Go to Settings → Security → Reset Password',
  },
  {
    'question': 'How to add a product?',
    'answer': 'Go to Seller Dashboard → Add Product → Fill the form',
  },
  {
    'question': 'How to track my order?',
    'answer': 'Go to Profile → Orders → Select your order',
  },
  {
    'question': 'How to contact seller?',
    'answer': 'Go to Product Details → Contact Seller',
  },
];

// Categories
final List<String> categories = [
  'All Items',
  'Clothing',
  'Toys',
  'Electronics',
  'Books',
  'Jewellery',
];

