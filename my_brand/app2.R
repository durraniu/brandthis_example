library(shiny)
library(shinychat)
library(bslib)
library(brand.yml)
library(brandthis)
library(thematic)
library(ggplot2)

library(future)
plan(multisession)

options(bslib.color_contrast_warnings = FALSE)


brand_path <- "my_brand/_brand.yml"

theme_brand <- bs_theme(brand = brand_path)

brand <- read_brand_yml(brand_path) #attr(theme_brand, "brand")

theme_set(theme_minimal())

thematic::thematic_shiny(
  font = brand_pluck(brand, "typography", "base", "family")
)


brand_sidebar <- sidebar(
    id = "sidebar_editor",
    position = "left",
    open = TRUE,
    width = "80%",
    bg = "var(--bs-dark)",
    fg = "var(--bs-light)",

    layout_sidebar(
        sidebar = sidebar(
          id = "chat_sidebar",
          open = FALSE,
          width = "40%",
          bg = "var(--bs-dark)",
          fg = "var(--bs-light)",
          chat_ui(
        id = "chat",
        messages = "**Hello!** How can I help you today?"
      )
    ),
 
    card(
      card_header(
        class = "text-bg-secondary hstack",
        div("Edit", code("brand.yml")),
        div(
          class = "ms-auto d-flex align-items-center gap-2",
                 actionLink(
                "show_chat",
                bsicons::bs_icon(
                  "stars",
                  size = "1.5rem",
                  title = "Show/hide editor"
                ),
                class = "nav-link"
              ),
          tooltip(
            tags$a(
              class = "btn btn-link p-0",
              href = "https://posit-dev.github.io/brand-yml/brand/",
              target = "_blank",
              bsicons::bs_icon(
                "question-square-fill",
                title = "About brand.yml",
                size = "1.25rem"
              )
            ),
            "About brand.yml"
          )
        )
      ),
      htmltools::tagAppendAttributes(
        textAreaInput(
          "txt_brand_yml",
          label = NULL,
          value = paste(readLines(brand_path, warn = FALSE), collapse = "\n"),
          width = "100%",
          height = "80%",
          rows = 20
        ),
        class = "font-monospace",
        .cssSelector = "textarea"
      ),
      card_body(
        padding = 0,
        div(
          id = "editor_brand_yml",
          style = "overflow: auto;",
          as_fill_item()
        )
      )
    )
       ),

    tags$script(
      type = "module",
      HTML(
        '
import { basicEditor } from "https://esm.sh/prism-code-editor@3.4.0/setups";
import "https://esm.sh/prism-code-editor@3.4.0/prism/languages/yaml";

const shinyInput = document.getElementById("txt_brand_yml");

function initBrandEditor() {
  if (typeof Shiny.setInputValue !== "function") {
    setTimeout(initBrandEditor, 100);
    return;
  }
  window.brandEditor = basicEditor(
    "#editor_brand_yml",
    {
      language: "yml",
      theme: "github-dark",
      value: shinyInput.value,
      onUpdate: (value) => {
        Shiny.setInputValue("txt_brand_yml", value);
      },
    },
    () => shinyInput.parentElement.parentElement.remove()
  );
}

initBrandEditor();
'
      )
    ),

    tags$style(
      HTML(
        '
.bslib-sidebar-layout .sidebar-title { margin-bottom: 0 }
#sidebar_editor .sidebar-content { height: max(600px, 100%) }'
      )
    ),
      shiny::downloadButton(
        "download",
        label = span("Download", code("_brand.yml"), "file"),
        class = "btn-outline-light"
      )
  )


page_dashboard <- nav_panel(
    "Input Output Demo",
    value = "dashboard",
    layout_sidebar(
      sidebar = sidebar(
        sliderInput("slider1", "Numeric Slider Input", 0, 11, 11),
        numericInput("numeric1", "Numeric Input Widget", 30),
        dateInput("date1", "Date Input Component", value = "2024-01-01"),
        input_switch("switch1", "Binary Switch Input", value = TRUE),
        radioButtons(
          "radio1",
          "Radio Button Group",
          choices = c("Option A", "Option B", "Option C", "Option D")
        ),
        actionButton("action1", "Primary Button")
      ),
      shiny::useBusyIndicators(),
      layout_column_wrap(
        value_box(
          title = "Primary Color",
          value = "100",
          theme = "primary",
          id = "value_box_one"
        ),
        value_box(
          title = "Secondary Color",
          value = "200",
          theme = "secondary",
          id = "value_box_two"
        ),
        value_box(
          title = "Info. Color",
          value = "300",
          theme = "info",
          id = "value_box_three"
        )
      ),
      card(
        card_header("Plot Output"),
        plotOutput("out_plot")
      ),
      card(
        card_header("Text Output"),
        verbatimTextOutput("out_text")
      )
    )
  )


errors <- rlang::new_environment()

error_notification <- function(context) {
  function(err) {
    time <- as.character(Sys.time())

    msg <- conditionMessage(err)
    # Strip ANSI color sequences from error messages
    msg <- gsub(
      pattern = "\u001b\\[.*?m",
      replacement = "",
      msg
    )
    # Wrap at 40 characters
    msg <- paste(strwrap(msg, width = 60), collapse = "\n")

    err_id <- rlang::hash(list(time, msg))
    assign(err_id, list(message = msg, context = context), envir = errors)

    showNotification(
      markdown(context),
      action = tags$button(
        class = "btn btn-outline-danger pull-right",
        onclick = sprintf(
          "event.preventDefault(); Shiny.setInputValue('show_error', '%s')",
          err_id
        ),
        "Show details"
      ),
      duration = 10,
      type = "error",
      id = err_id
    )
  }
}

ui <- page_navbar(
  theme = theme_brand,
  title = "brand.yml Demo",
  fillable = TRUE,
  sidebar = brand_sidebar,
  page_dashboard
)


server <- function(input, output, session) {
  brand_yml_text <- debounce(reactive(input$txt_brand_yml), 1000)
  brand_yml <- reactiveVal()

  observeEvent(input$show_error, {
    req(input$show_error)
    err <- get0(input$show_error, errors)

    if (is.null(err)) {
      message("Could not find error with id ", input$show_error)
      return()
    }

    removeNotification(input$show_error)
    rm(list = input$show_error, envir = errors)

    showModal(
      modalDialog(
        size = "l",
        easyClose = TRUE,
        markdown(err$context),
        pre(err$message)
      )
    )
  })

observeEvent(input$show_chat, sidebar_toggle("chat_sidebar"))

  observeEvent(brand_yml_text(), {
    req(brand_yml_text())

    tryCatch(
      {
        b <- yaml::yaml.load(brand_yml_text())
        b$path <- normalizePath(brand_path)
        brand_yml(b)
      },
      error = error_notification(
        "Could not parse `_brand.yml` file. Check for syntax errors."
      )
    )
  })

  observeEvent(brand_yml(), {
    req(brand_yml())

    tryCatch(
      {
        theme <- bs_theme(brand = brand_yml())
        session$setCurrentTheme(theme)
      },
      error = error_notification(
        "Could not compile branded theme. Please check your `_brand.yml` file."
      )
    )
  })

  output$download <- downloadHandler(
    filename = "_brand.yml",
    content = function(file) {
      validate(
        need(input$txt_brand_yml, "_brand.yml file contents cannot be empty.")
      )
      writeLines(input$txt_brand_yml, file)
    }
  )


  PlotTask <- ExtendedTask$new(function(x_max, y_factor) {
    x <- seq(0, x_max, length.out = 100)
    y <- sin(x) * y_factor

    future({
      Sys.sleep(3)

      df <- data.frame(x = x, y = y)

      ggplot(df, aes(x = x, y = y)) +
        geom_col(width = 1, position = "identity") +
        labs(title = "Sine Wave Output", x = "", y = "")
    })
  })

  observe({
    x_max <- debounce(reactive(input$numeric1), 500)()
    y_factor <- debounce(reactive(input$slider1), 500)()

    PlotTask$invoke(x_max = x_max, y_factor = y_factor)
  })

  output$out_plot <- renderPlot({
    PlotTask$result()
  })

  output$out_text <- renderText({
    "example_function <- function() {\n  return(\"Function output text\")\n}"
  })

  client_brand <- brandthis::chat_brand(ellmer::chat_github, model = "gpt-4.1")

    observeEvent(input$chat_user_input, {
    stream <- client_brand$stream_async(input$chat_user_input)
    chat_append("chat", stream)
  })

}

shinyApp(ui, server)