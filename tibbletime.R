# Rolling calculations in tibbletime
library(tibbletime)
library(dplyr)
library(tidyr)

# Facebook stock prices.
data(FB)

# Only a few columns
FB <- select(FB, symbol, date, open, close, adjusted)
# The function to use at each step is `mean`.
# The window size is 5
rolling_mean <- rollify(mean, window = 5)

rolling_mean
mutate(FB, mean_5 = rolling_mean(adjusted))

rolling_mean_2 <- rollify(mean, window = 2)
rolling_mean_3 <- rollify(mean, window = 3)
rolling_mean_4 <- rollify(mean, window = 4)

FB %>% mutate(
  rm10 = rolling_mean_2(adjusted),
  rm20 = rolling_mean_3(adjusted),
  rm30 = rolling_mean_4(adjusted)
)

# Our data frame summary
summary_df <- function(x) {
  data.frame(  
    rolled_summary_type = c("mean", "sd",  "min",  "max",  "median"),
    rolled_summary_val  = c(mean(x), sd(x), min(x), max(x), median(x))
  )
}

# A rolling version, with unlist = FALSE
rolling_summary <- rollify(~summary_df(.x), window = 5, 
                           unlist = FALSE)

FB_summarised <- mutate(FB, summary_list_col = rolling_summary(adjusted))
FB_summarised

FB_summarised %>% 
  filter(!is.na(summary_list_col)) %>%
  unnest(cols = c(summary_list_col))

rolling_summary <- rollify(~summary_df(.x), window = 5, 
                           unlist = FALSE, na_value = data.frame())

FB_summarised <- mutate(FB, summary_list_col = rolling_summary(adjusted))
FB_summarised

FB_summarised %>% 
  unnest(cols = c(summary_list_col))

rolling_summary <- rollify(~summary_df(.x), window = 5, 
                           unlist = FALSE, 
                           na_value = data.frame(rolled_summary_type = NA,
                                                 rolled_summary_val  = NA))

FB_summarised <- mutate(FB, summary_list_col = rolling_summary(adjusted))
FB_summarised %>% unnest(cols = c(summary_list_col))

# Reset FB
data(FB)

rolling_lm <- rollify(.f = function(close, high, low, volume) {
  lm(close ~ high + low + volume)
}, 
window = 5, 
unlist = FALSE)

FB_reg <- mutate(FB, roll_lm = rolling_lm(close, high, low, volume))
FB_reg

FB_reg %>%
  filter(!is.na(roll_lm)) %>%
  mutate(tidied = purrr::map(roll_lm, broom::tidy)) %>%
  unnest(tidied) %>%
  select(symbol, date, term, estimate, std.error, statistic, p.value)
