create_palette_from_image <- function(img, n = 5){
  colz <- colorfindr::get_colors(img) 
  pal <- colorfindr::make_palette(colz, n, 
    extract_method = "median", show = FALSE)
  pal
}

load(file = "inst/extdata/fonts.rda")
fonts_vector <- function(){
  sample(fonts, 1)
}


brand_instructions <-  paste(readLines("inst/extdata/brand_yml_instructions.txt"), collapse = "\n")


sys_prompt_brand <- paste(
    # "You create _brand.yml files. 
    # A user may provide you with an 1. image, 2. font names, 3. logo info., etc.
    # If an image is provided, you HAVE TO extract colors from it BY CALLING 
    # the create_palette_from_image tool. 
    # Using this palette to create the semantic colors for _brand.yml.
    # If no image is provided, use any color info. provided by the user
    # or use your knowledge of best practice about colors to select colors.
    "You create _brand.yml files.
    If a color palette is provided to you, use that and your own knowledge
    to create semantic colors for _brand.yml.
    If font names are provided, use them for 
    base, heading, and monospace fonts as instructed. If one ore more
    font names are not provided, you HAVE TO CALL the fonts_vector_tool to get a 
    pair of heading and base fonts,
    and select 'Fira Code' for monospace font.
    Provide a complete _brand.yml file and do not skip any section. 
    Do not include any other text or instructions. 
    Do not say anything before or after the _brand.yml 
    related text i.e., everything should be inside the 
    backticks for the _brand.yml. Here is all the info about _brand.yml file:\n",
    brand_instructions
  )

chat_brand <- ellmer::chat_google_gemini(
  system_prompt = sys_prompt_brand
)

# create_palette_from_image_tool <- ellmer::tool(
#   create_palette_from_image,
#   name = "create_palette_from_image",
#   description = "Returns a vector of colors.",
#   arguments = list(
#     img = ellmer::type_string(
#       "Path or url to image.",
#       required = TRUE
#     ),
#     n = ellmer::type_integer(
#       "The number of discrete colors to be extracted.",
#       required = FALSE
#     )
#   )
# )

fonts_vector_tool <- ellmer::tool(
  fonts_vector,
  name = "fonts_vector",
  description = "Returns a vector of 50 pairs of google fonts. H indicates heading font and B indicates body font."
)

# chat_brand$register_tool(create_palette_from_image_tool)
chat_brand$register_tool(fonts_vector_tool)



user_prompt <- "Create a _brand.yml for my personal brand. 
                My name is Big Head."
img_url <-  "squirrel_tail_bushy_tail.jpg" 

my_colors <- create_palette_from_image(img_url)

# chat_brand$chat(
#   paste(user_prompt, "Image is attached for you to extract colors from."),
#   ellmer::content_image_file(img_url)  
# )

# chat_brand$chat(
#   paste(user_prompt, "The initial color palette is:", paste(my_colors, collapse=", "))
# )

type_brand_yml <- ellmer::type_string("A complete _brand.yml file. Do not add any commentary or extra text.")

res_brand_yml <- chat_brand$chat_structured(
  paste(user_prompt, "The initial color palette is:", paste(my_colors, collapse=", ")),
  type = type_brand_yml
)

# res_brand_yml <- chat_brand$chat_structured(
#   ellmer::content_image_file(img_url),
#   user_prompt,
#   type = type_brand_yml
# )

# shiny::runExample("brand.yml", package = "bslib")
