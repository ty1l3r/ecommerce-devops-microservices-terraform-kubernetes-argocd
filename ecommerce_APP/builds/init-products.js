/**
 * Script d'Initialisation de Base de Données MongoDB pour Tests
 * ============================================================
 * 
 * Ce script est conçu pour initialiser automatiquement la base de données
 * MongoDB 'products_db' avec des données de test prédéfinies. Il sert de
 * mécanisme de chargement de données pour les environnements de développement,
 * de test et de staging.
 * 
 * Caractéristiques:
 * - Exécution automatisée dans la pipeline CI/CD
 * - Génération de données de test cohérentes entre environnements
 * - Vérification intégrée de la réussite de l'insertion
 * - Support pour différents types de produits (fruits, légumes, huiles)
 * 
 * Structure de données:
 * Chaque produit contient les champs suivants:
 * - name: Nom du produit
 * - desc: Description du produit
 * - type: Catégorie du produit (fruits, vegetables, oils)
 * - banner: URL de l'image
 * - unit: Quantité unitaire
 * - price: Prix en centimes
 * - available: Statut de disponibilité
 * - suplier: Nom du fournisseur
 * 
 * Note: Ce script est destiné aux environnements de test uniquement et
 * ne devrait pas être utilisé en production sans modification.
 */

db = db.getSiblingDB('products_db');
db.products.insertMany([
   {
       "name": "alphonso mango",
       "desc": "great Quality of Mango",
       "type": "fruits",
       "banner": "https://images.pexels.com/photos/1464609/pexels-photo-1464609.jpeg",
       "unit": 1,
       "price": 300,
       "available": true,
       "suplier": "Golden seed firming"
   },
   {
       "name": "Apples",
       "desc": "great Quality of Apple",
       "type": "fruits",
       "banner": "https://cdn.pixabay.com/photo/2022/05/27/10/57/apples-7224924_1280.jpg",
       "unit": 1,
       "price": 140,
       "available": true,
       "suplier": "Golden seed firming"
   },
   {
       "name": "Kesar Mango",
       "desc": "great Quality of Mango",
       "type": "fruits",
       "banner": "https://cdn.pixabay.com/photo/2015/08/19/15/58/mango-896189_1280.jpg",
       "unit": 1,
       "price": 170,
       "available": true,
       "suplier": "Golden seed firming"
   },
   {
       "name": "Langra Mango",
       "desc": "great Quality of Mango",
       "type": "fruits",
       "banner": "https://cdn.pixabay.com/photo/2012/02/29/16/01/mango-19320_1280.jpg",
       "unit": 1,
       "price": 280,
       "available": true,
       "suplier": "Golden seed firming"
   },
   {
       "name": "Broccoli",
       "desc": "great Quality of Fresh Vegetable",
       "type": "vegetables",
       "banner": "https://cdn.pixabay.com/photo/2016/03/05/19/02/broccoli-1238250_1280.jpg",
       "unit": 1,
       "price": 280,
       "available": true,
       "suplier": "Golden seed firming"
   },
   {
       "name": "Cauliflower",
       "desc": "great Quality of Fresh Vegetable",
       "type": "vegetables",
       "banner": "https://cdn.pixabay.com/photo/2015/09/25/16/51/cabbage-957778_1280.jpg",
       "unit": 1,
       "price": 280,
       "available": true,
       "suplier": "Golden seed firming"
   },
   {
       "name": "Olive Oil",
       "desc": "great Quality of Oil",
       "type": "oils",
       "banner": "https://cdn.pixabay.com/photo/2014/05/28/00/27/olive-oil-356102_1280.jpg",
       "unit": 1,
       "price": 400,
       "available": true,
       "suplier": "Golden seed firming"
   }
]);

// Vérification de l'insertion
print("Produits insérés avec succès. Vérification :");
db.products.find().forEach(printjson);