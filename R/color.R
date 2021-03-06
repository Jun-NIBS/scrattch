#' Generate a weave plot based on a palette of colors
#' 
#' @param palette a character vector containing colors as either hex values (starting with #) or R colors
#' 
#' @return a ggplot2 plot showing all intersections of the palette.
#' 
weave_plot <- function(palette) {
  
  n <- length(palette)
  
  h_data <- data.frame(xmin = 2*1:n,
                       xmax = 2*2:(n + 1) - 1,
                       ymin = 1,
                       ymax = n*2+2,
                       fill = palette)
  
  ggplot2::ggplot() +
    ggplot2::geom_rect(data = h_data,
                       ggplot2::aes(xmin = xmin, 
                                    xmax = xmax,
                                    ymin = ymin, 
                                    ymax = ymax,
                                    fill = fill)) +
    ggplot2::geom_rect(data = h_data,
                       ggplot2::aes(xmin = ymin, 
                                    xmax = ymax,
                                    ymin = xmin,
                                    ymax = xmax,
                                    fill = fill)) +
    ggplot2::scale_fill_identity() +
    ggplot2::scale_y_reverse() +
    ggplot2::theme_classic()
  
}

#' Generate a palette of related colors around a central color
#' 
#' @param central_color a single color value around which to build the palette
#' 
#' @return a list of palette results, containing:
#' \itemize{
#' \item palette: a character vector with a 10-color palette realted to the central_color.
#' \item palette_plot: a ggplot2 object showing the 10 colors in palette.
#' \item colorset: A character vector with the full set of 100 colors from which the palette was selected.
#' \item colorset_plot: A ggplot2 object displaying all 100 colors in the colorset.
#' \item weave: a ggplot2 object generated with weave_plot() showing the intersection of all of the collors in the palette.
#' }
#' 
build_palette <- function(central_color) {
  
  central_hsv <- grDevices::rgb2hsv(grDevices::col2rgb(central_color))
  
  central_hue <- central_hsv[1,1]
  central_sat <- central_hsv[2,1]
  central_val <- central_hsv[3,1]
  
  hue_set <- seq(central_hue - 0.049,central_hue + 0.05,0.001)
  hue_set[hue_set < 0] <- 1 + hue_set[hue_set < 0]
  hue_set[hue_set > 1] <- hue_set[hue_set > 1] - 1
  
  if(central_val > 0.8) {
    central_val <- 0.8
  } else if(central_val < 0.4) {
    central_val <- 0.4
  }
  val_set <- rep(seq(central_val - 0.25, central_val + 0.2, 0.05),10)
  
  colorset <- grDevices::hsv(h = hue_set,
                             s = central_sat,
                             v = val_set)
  
  set_nums <- c(68,10,65,50,100,35,84,38,14)
  
  colorset_plot_data <- data.frame(x = rep(1:10,each = 10),
                                   y = rep(1:10, 10),
                                   fill = colorset,
                                   number = 1:100) %>%
    mutate(color = ifelse(number %in% set_nums, "white","black"))
  
  colorset_plot <- ggplot2::ggplot(colorset_plot_data) +
    ggplot2::geom_tile(ggplot2::aes(x = x, y = y, fill = fill)) +
    ggplot2::geom_text(ggplot2::aes(x = x, y = y, label = number, color = color)) +
    ggplot2::scale_fill_identity() +
    ggplot2::scale_color_identity()
  
  palette <- colorset[set_nums]
  
  palette_plot_data <- data.frame(x = 1:9, y = 1, fill = palette, number = set_nums)
  
  palette_plot <- ggplot2::ggplot(palette_plot_data) +
    ggplot2::geom_tile(ggplot2::aes(x = x, y = y, fill = fill)) +
    ggplot2::geom_text(ggplot2::aes(x = x, y = y, label = number)) +
    ggplot2::scale_fill_identity()
  
  weave <- weave_plot(palette)
  
  results <- list(palette = palette,
                  palette_plot = palette_plot,
                  colorset = colorset,
                  colorset_plot = colorset_plot,
                  weave = weave)
}

#' Mix two colors additively in RGB space
#' 
#' @param col1 A hex or R color
#' @param col2 Another hex or R color
#' @return The sum of col1 and col2 as a character hex color (e.g. "#FFFFFF")
#' 
#' @examples
#' color_sum("red","green")
#' 
#' color_sum("#1B9E77","#D95F02")
color_sum <- function(col1,col2) {
  
  rgbmat1 <- grDevices::col2rgb(col1)/255
  rgbmat2 <- grDevices::col2rgb(col2)/255
  
  mix <- rgbmat1 + rgbmat2
  
  mix[mix > 1] <- 1
  mix[mix < 0] <- 0
  
  rgb(mix[1],mix[2],mix[3])
  
}

#' Compute the mean of multiple colors in RGB space
#' 
#' @param color_vec A vector of hex or R colors
#' @return The mean of the colors as a character hex color (e.g. "#FFFFFF")
#' 
color_mean <- function(color_vec) {
  rgbmat <- grDevices::col2rgb(color_vec)/255
  means <- rowMeans(rgbmat)
  rgb(means[1], means[2], means[3])
}

#' Convert values to colors along a color ramp
#' 
#' @param x a numeric vector to be converted to colors
#' @param min_val a number that's used to set the low end of the color scale (default = 0)
#' @param max_val a number that's used to set the high end of the color scale. If NULL (default), 
#' use the highest value in x
#' @param colorset a set of colors to interpolate between using colorRampPalette 
#' (default = c("darkblue","dodgerblue","gray80","orangered","red"))
#' @param missing_color a color to use for missing (NA) values.
#' 
#' @return a character vector of hex color values generated by colorRampPalette. Color values will
#' remain in the same order as x.
#' 
values_to_colors <- function(x, 
                             min_val = NULL, 
                             max_val = NULL, 
                             colorset = c("darkblue","dodgerblue","gray80","orange","orangered"),
                             missing_color = "black") {
  
  heat_colors <- grDevices::colorRampPalette(colorset)(1001)
  
  if (is.null(max_val)) {
    max_val <- max(x, na.rm = T)
  } else {
    x[x > max_val] <- max_val
  }
  if (is.null(min_val)) {
    min_val <- min(x, na.rm = T)
  } else {
    x[x < min_val] <- min_val
  }
  
  if (sum(x == min_val, na.rm = TRUE) == length(x)) {
    colors <- rep(heat_colors[1],length(x))
  } else {
    if (length(x) > 1) {
      if (var(x, na.rm = TRUE) == 0) {
        colors <- rep(heat_colors[500], length(x))
      } else {
        heat_positions <- unlist(round((x - min_val) / (max_val - min_val) * 1000 + 1, 0))
        
        colors <- heat_colors[heat_positions]
      }
    } else {
      colors <- heat_colors[500]
    }
  }
  
  if (!is.null(missing_color)) {
    colors[is.na(colors)] <- rgb(t(col2rgb(missing_color)/255))
  }
  
  colors
}

#' Generate a rainbow palette with variation in saturation and value
#'
#' @param n_colors The number of colors to generate
#'
#' @return a character vector of hex color values of length n_colors.
#' 
varibow <- function(n_colors) {
  sats <- rep_len(c(0.55,0.7,0.85,1),length.out = n_colors)
  vals <- rep_len(c(1,0.8,0.6),length.out = n_colors)
  sub("FF$","",grDevices::rainbow(n_colors, s = sats, v = vals))
}

#' Convert colors to alpha-beta values
#' 
#' See https://en.wikipedia.org/wiki/HSL_and_HSV#Hue_and_chroma for more information.
#' 
#' @param hexes A character vector with a set of hex color values or R colors
#'
#' @return a data.frame with columns for the original color, alpha, and beta values.
#'
col2ab <- function(hexes) {
  rgbs <- col2rgb(hexes) / 255
  alphas <- rgbs["red",] - 0.5 * (rgbs["green",] + rgbs["blue",])
  betas <- sqrt(3) / 2 * (rgbs["green",] - rgbs["blue",])
  return(data.frame(color = hexes,
                    alpha = alphas,
                    beta = betas))
}

#' Generate a plot in alpha-beta colorspace for a palette
#'
#' The resulting plot will be a 2-D projection onto the HSV/HSL chromaticity plane.
#' See https://en.wikipedia.org/wiki/HSL_and_HSV#Hue_and_chroma for more information.
#' 
#' @param palette a character vector containing colors as either hex values (starting with #) or R colors
#' @param show_pures a logical value indicating whether or not to plot points for pure colors
#'
#' @return a ggplot2 plot with palette colors in alpha-beta space.
#'
colorspace_plot <- function(palette,
                            show_pures = TRUE) {

  data <- col2ab(colorspace_plot)

  p <- ggplot(data) +
    geom_point(aes(x = alpha,
                   y = beta,
                   color = color),
               size = 2) +
    scale_color_identity() +
    theme_classic() +
    scale_x_continuous(limits = c(-1.1,1.1)) +
    scale_y_continuous(limits = c(-1.1,1.1))

  if(show_pures) {
    pure_colors <- c("#FF0000","#FFFF00","#00FF00","#00FFFF","#0000FF","#FF00FF")
    pure_df <- col2ab(pure_colors)
    p <- p + geom_point(data = pure_df,
                        aes(x = alpha,
                            y = beta,
                            fill = color),
                        size = 4,
                        pch = 21) +
      scale_fill_identity()
  }

  return(p)
}
