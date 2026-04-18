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
        print(f"[ShapePro AI] Researching food prices for {cidade}, {pais}...")
        
        # Base prices in USD (will be converted or used as base)
        base_prices = {
            "Peito de Frango": 5.50,
            "Chicken Breast": 5.50,
            "Arroz Integral": 2.00,
            "Brown Rice": 2.00,
            "Ovos (12 un)": 3.00,
            "Eggs (12 units)": 3.00,
            "Batata Doce": 1.50,
            "Sweet Potato": 1.50,
            "Banana": 0.80,
            "Banana (unit)": 0.30,
            "Brócolis": 2.50,
            "Broccoli": 2.50,
            "Pasta de Amendoim": 4.00,
            "Peanut Butter": 4.00,
            "Aveia": 2.20,
            "Oats": 2.20,
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
        print(f"[ShapePro AI] Price research finished. {len(base_prices)} prices saved for {cidade}.")
        return True
