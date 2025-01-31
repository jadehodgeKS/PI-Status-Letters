
# PI status Letter Instruction Script

# 1. Load Packages -------------------------------------------------------------------------
pacman::p_load(
  rio,          # for importing data
  here,         # for file paths
  janitor,      # for data cleaning
  lubridate,    # for working with dates
  tidyverse,    # for data management
  purrr,        # for working with functions
  dplyr,        # just in case
  readxl,       # to read excel
  quarto,       # to render many reports at once
  fs,            # to list files
  tinytex,
  quarto
)

    # tinytex::install_tinytex()

# 2. Import Data ---------------------------------------------------------------------------
PI_status_raw <- read_excel(here("data", "PI_Status.xlsx"), 
           col_names = TRUE,
           na = "NA") %>% 
  clean_names()


# 3. Clean Data, recode AE levels ---------------------------------------------------------
PI_status <- PI_status_raw %>% 
  select('organization_name', 'facility_name', 'iz', 'elr', 'ss', 'ecr') %>% 
  mutate_at(c("iz", "elr", "ss", "ecr"), 
            funs(recode(.,
                           "AE1" = "Active Engagement 1 – Pre-production and Validation",
                           "AE2" = "Active Engagement 2 – Validated Data Production"
                           )))


# 4. Create df of file names, output type, and list of parameter ---------------------------------
render_args <- PI_status %>% 
  distinct(organization_name, facility_name) %>%        # Have to remove duplicates
  mutate(                                               # Adding columns: output_format and output_file
    output_format = "pdf",
    output_file = paste0(     # Use Regular Expressions (regex) to remove characters and add file extension
      str_squish(str_remove_all(facility_name, "[:punct:]|[:symbol:]")), 
      "_PI.pdf"),
    execute_params = map2(    # Use purrr:map2 to create execute_params column, a list of 2 variables
      organization_name,
      facility_name,
      \(organization_name, facility_name)
      list(organization_name = organization_name, facility_name = facility_name))
    )


# 5. Subset render_args by organization or single facility ----------------------------------------------
    
  # Subset of render_args by organization
  # adjust org_name or single_facility inside quotes

org_name <- "Healthcare Health"

organization <- render_args %>% 
  filter(organization_name == org_name) %>% 
  select(output_file, output_format, execute_params)


  # OR Subset of render_args by single facility
  # adjust org_name or single_facility inside quotes

# single_facility <- "Medical Group of Kansas City - Overland Park"
# 
# facility <- render_args %>%
#   filter(facility_name == single_facility
#          ) %>%
#   select(output_file, output_format, execute_params)


# 6. Render ----------------------------------------------------------------------
  # Update .l to "organization" or "facility", same as used in step 5  
  # Update input with name of qmd file from list
      # List of possible files: year_PI_status_update.qmd, PI_status_update.qmd

purrr::pwalk(
  .l = organization,                  # data frame, use 'organization' or 'facility'
  .f = quarto::quarto_render,         
  input = here("scripts", "PI_status_update.qmd"),  # change name of qmd file
  .progress = TRUE
)

# 7. Move all letters created to "pdf_output" folder ----------------------------------
output_dir <- "pdf_output"
files <- dir_ls(here(), regexp = ".pdf$")
file_move(files, output_dir)


## Quarto render function
# quarto::quarto_render(
#   input = here("scripts", "PI_status_update.qmd"),
#   output_format = "pdf",
#   output_file = "PI_status.pdf",
#   execute_params = list(
#     facility_name = "Menorah Medical Center"
#   )
# )
