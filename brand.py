from colorthief import ColorThief
import pickle
import random
from chatlas import ChatGoogle, Tool
from pydantic import BaseModel, Field
from dotenv import load_dotenv

load_dotenv()

with open("fonts.pkl", "rb") as f:
    fonts = pickle.load(f)

def fonts_vector():
    return random.choice(fonts)

def rgb_to_hex(r, g, b):
    return f"#{r:02x}{g:02x}{b:02x}"

def create_palette_from_image(img_path):
    color_thief = ColorThief(img_path)
    palette = color_thief.get_palette(color_count=5, quality=1)
    pal = [rgb_to_hex(*rgb) for rgb in palette]
    return pal


with open("inst/extdata/brand_yml_instructions.txt", "r") as f:
    brand_instructions = f.read()


sys_prompt_brand = (
    "You create _brand.yml files.\n"
    "If a color palette is provided to you, use that and your own knowledge "
    "to create semantic colors for _brand.yml.\n"
    "If font names are provided, use them for "
    "base, heading, and monospace fonts as instructed. If one or more "
    "font names are not provided, you HAVE TO CALL the fonts_vector_tool to get a "
    "pair of heading and base fonts, "
    "and select 'Fira Code' for monospace font.\n"
    "Provide a complete _brand.yml file and do not skip any section.\n"
    "Do not include any other text or instructions.\n"
    "Do not say anything before or after the _brand.yml "
    "related text i.e., everything should be inside the "
    "backticks for the _brand.yml. Here is all the info about _brand.yml file:\n"
    f"{brand_instructions}"
)


chat_brand = ChatGoogle(
    system_prompt=sys_prompt_brand
)

fonts_vector_tool = Tool(
  func=fonts_vector,
  name="fonts_vector",
  description="Returns a vector of 50 pairs of google fonts. H indicates heading font and B indicates body font.",
  parameters=[]
)

chat_brand.register_tool(fonts_vector_tool)

user_prompt = "Create a _brand.yml for my personal brand. My name is Big Head."

img =  "squirrel_tail_bushy_tail.jpg" 
my_colors = create_palette_from_image(img)
my_colors = ", ".join(my_colors)

chat_brand.chat(f"{user_prompt} The initial color palette is {my_colors}")

# class BrandYML(BaseModel):
#     content: str = Field(description="A complete _brand.yml file. Do not add any commentary or extra text.")

# response = chat_brand.chat_structured(
#     f"{user_prompt} The initial color palette is {my_colors}",
#     data_model=BrandYML
# )

# # Access the yml content
# res_brand_yml = response.content