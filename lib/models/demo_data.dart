import '../models/product.dart';
import '../models/user_model.dart';
import '../models/order.dart';
import '../models/seller_model.dart';
import '../models/admin_model.dart';

// Demo Products
// Demo Products
final List<Product> demoProducts = [
  Product(
    id: '1',
    name: 'Antique Diamond Ring',
    categoryId: 'Jewellery',
    description: 'Beautiful antique diamond ring with exquisite craftsmanship.',
    basePrice: 150000,
    stockQuantity: 10,
    createdAt: DateTime.now(),
    images: [
      ProductImage(id: 'img1', productId: '1', url: 'assets/images/ring.png', displayOrder: 0, isPrimary: true)
    ],
    averageRating: 5.0,
    reviewCount: 12,
    specifications: {
      'size': '5',
      'color': 'silver',
      'Quality': 'A+',
    },
    sellerId: 'seller1',
    status: ProductStatus.approved,
  ),
  Product(
    id: '2',
    name: 'Modern light clothes',
    categoryId: 'Clothing',
    description: 'Comfortable and stylish modern clothing.',
    basePrice: 4500,
    stockQuantity: 50,
     createdAt: DateTime.now(),
    images: [
       ProductImage(id: 'img2', productId: '2', url: 'assets/images/clothes.png', displayOrder: 0, isPrimary: true)
    ],
    averageRating: 5.0,
    reviewCount: 8,
    specifications: {
      'size': 'M',
      'color': 'Light',
      'Material': 'Cotton',
    },
    sellerId: 'seller2',
    status: ProductStatus.approved,
  ),
  Product(
    id: '3',
    name: 'Harry Potter Series II',
    categoryId: 'Books',
    description: 'Harry Potter and the Cursed Child is a play written by Jack Thorne from an original story by Thorne, J. K. Rowling, and John Tiffany.',
    basePrice: 4500,
    stockQuantity: 20,
     createdAt: DateTime.now(),
    images: [
       ProductImage(id: 'img3', productId: '3', url: 'assets/images/book.png', displayOrder: 0, isPrimary: true)
    ],
    averageRating: 4.5,
    reviewCount: 25,
    specifications: {
      'Author': 'J.K. Rowling',
      'Pages': '320',
      'Language': 'English',
    },
    sellerId: 'seller1',
    status: ProductStatus.approved,
  ),
  Product(
    id: '4',
    name: 'Light Dress Bless',
    categoryId: 'Clothing',
    description: 'Elegant light dress perfect for any occasion.',
    basePrice: 4500,
    stockQuantity: 5,
     createdAt: DateTime.now(),
    images: [
       ProductImage(id: 'img4', productId: '4', url: 'assets/images/dress.png', displayOrder: 0, isPrimary: true)
    ],
    averageRating: 5.0,
    reviewCount: 15,
    specifications: {
      'size': 'S',
      'color': 'Pink',
      'Material': 'Silk',
    },
    sellerId: 'seller2',
    status: ProductStatus.pending,
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
    userId: 'user1',
    businessName: 'Aryan Mirza',
    businessCategory: 'Jewellery',
    description: 'Best Jewellery in town',
    whatsappNumber: '+92 304 0974326',
    status: 'pending',
    totalSales: 250000.0,
    walletBalance: 0.0,
    createdAt: DateTime.now(),
  ),
  Seller(
    id: 'seller2',
    userId: 'user2',
    businessName: 'Ali Khan',
    businessCategory: 'Clothing',
    description: 'Best Clothing in town',
    whatsappNumber: '+92 300 1234567',
    status: 'approved',
    totalSales: 500000.0,
    walletBalance: 0.0,
    createdAt: DateTime.now(),
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
    addressId: 'addr1',
    items: [
      OrderItem(
        id: 'item1',
        orderId: 'order1',
        productId: '2',
        productName: 'Modern light clothes',
        sellerId: 'seller2',
        quantity: 1,
        unitPrice: 4500,
        totalPrice: 4500,
      ),
      OrderItem(
        id: 'item2',
        orderId: 'order1',
        productId: '1',
        productName: 'Antique Diamond Ring',
        sellerId: 'seller1',
        quantity: 1,
        unitPrice: 150000,
        totalPrice: 150000,
      ),
    ],
    subtotal: 154500,
    platformCommission: 15450,
    total: 154500,
    status: OrderStatus.delivered,
    paymentMethod: 'visa',
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
  ),
  Order(
    id: 'order2',
    userId: 'user1',
    addressId: 'addr1',
    items: [
      OrderItem(
        id: 'item3',
        orderId: 'order2',
        productId: '3',
        productName: 'Harry Potter Series II',
        sellerId: 'seller1',
        quantity: 1,
        unitPrice: 4500,
        totalPrice: 4500,
      ),
    ],
    subtotal: 4500,
    platformCommission: 450,
    total: 4500,
    status: OrderStatus.pending,
    paymentMethod: 'jazzcash',
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
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

