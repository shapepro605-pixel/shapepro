import random
from database import db
from models.food_price import FoodPrice
from datetime import datetime

class FoodPriceService:
    @staticmethod
    def simulate_ai_research(pais, cidade):
        """
        Simulates an AI researching prices for common foods in a specific region.
        In a real scenario, this would call a search API or scrape local supermarkets.
        """
        
        # Base prices in USD (Retail/Supermarket average)
        base_prices = {
            "Peito de Frango": 4.50, # ~R$ 23/kg
            "Chicken Breast": 4.50,
            "Arroz Integral": 2.20, # ~R$ 11/kg
            "Brown Rice": 2.20,
            "Ovos (12 un)": 2.80, # ~R$ 14.50/doz
            "Eggs (12 units)": 2.80,
            "Batata Doce": 1.80, # ~R$ 9.30/kg
            "Sweet Potato": 1.80,
            "Patinho Bovino": 9.50, # ~R$ 49/kg
            "Top Side Beef": 9.50,
            "Banana": 1.20, # ~R$ 6.20/kg
            "Maçã": 2.50, # ~R$ 13/kg
            "Apple": 2.50,
            "Brócolis": 3.00,
            "Broccoli": 3.00,
        }

        # Multipliers based on country/economy
        multipliers = {
            'BR': 5.0, # Approximate BRL/USD parity for food index simulation
            'US': 1.0,
            'CA': 1.3,
            'GB': 0.8,
        }

        moedas = {
            'BR': 'BRL',
            'US': 'USD',
            'CA': 'CAD',
            'GB': 'GBP',
        }

        multiplier = multipliers.get(pais, 1.0)
        moeda = moedas.get(pais, 'USD')

        # Add some randomness to city vs country prices (+/- 15%)
        city_factor = 1.0 + (random.uniform(-0.15, 0.15))

        for alimento, base_price in base_prices.items():
            final_price = round(base_price * multiplier * city_factor, 2)
            
            # Save or Update
            price_entry = FoodPrice(
                alimento=alimento,
                preco=final_price,
                moeda=moeda,
                cidade=cidade,
                pais=pais,
                origem='ia_estimate',
                data_atualizacao=datetime.utcnow()
            )
            db.session.add(price_entry)
        
        db.session.commit()
        return True
