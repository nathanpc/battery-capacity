#' battery_capacity.R
#' Plots and analyzes battery capacity.
#' 
#' @author Nathan Campos <nathanpc@dreamintech.net>

library("ggplot2")
library("scales")
library("RColorBrewer")
rm(list = ls(all = TRUE))  # Clear the workspace.
datadir <- "data"
cachedir = "cache"

#' Get the battery discharge data from the log file.
#' 
#' @param name Battery name to be displayed on the legend.
#' @param file Log file location.
#' @param current Discharge current.
#' @param cutoff Voltage cutoff point to ignore when plotting.
#' @param interval Sampling interval in seconds.
#' @return A data frame with the battery data.
battery_discharge <- function (name, file, current, cutoff, interval) {
  csv = read.csv(file, header = FALSE)
  volts = csv[[3]]
  mah = c()

  # Calculate the capacity and voltage at a point.
  for (i in 0:(length(volts) - 1)) {
    mah = c(mah, current * ((i * interval) / 3600))
    
    # Stop appending data to the list when the cutoff point has been reached.
    if (i > 0 && volts[i] < cutoff) {
      length(volts) <- i + 1
      break;
    }
  }
  
  return(data.frame(voltage = volts, mah = mah, name = name))
}

#' Get batteries by type and returns a data frame with information about each.
#' 
#' @param type Battery type.
#' @return A list with the data frames with battery data from the index file.
get_batteries_df <- function (type) {
  csv = read.csv(paste(datadir, type, "index.csv", sep = "/"))
  batts = data.frame(index = 1:nrow(csv))
  delete = c()

  for (i in 1:nrow(csv)) {
    battery = csv[i,]
    
    if (battery$show == 1) {
      batts$Brand[i] = sprintf("%s", battery$brand)
      batts$Model[i] = sprintf("%s", battery$model)
      batts$Voltage[i] = battery$voltage
      batts$Expected_Capacity[i] = battery$exp_capacity
      batts$Current[i] = battery$current
      batts$Type[i] = sprintf("%s", battery$type)
      batts$Interval[i] = battery$interval
      batts$Comment[i] = sprintf("%s", battery$comment)
    } else {
      delete = c(delete, i)
    }
  }
  
  if (length(delete) > 0) {
    batts = batts[-delete,]
  }

  batts$index = NULL
  return(batts)
}

#' Get batteries data by type.
#' 
#' @param type Battery type.
#' @param cached Get the data from the cache or from the raw data dir.
#' @return A list with the data frames from `battery_discharge`
#' @seealso battery_discharge
get_batteries <- function (type, cached = TRUE) {
  batts = list()
  
  if (cached) {
    batts = readRDS(paste0(cachedir, "/", type, ".rds"))
  } else {
    csv = read.csv(paste(datadir, type, "index.csv", sep = "/"))
    for (i in 1:nrow(csv)) {
      battery = csv[i,]
      
      if (battery$show == 1) {
        model = battery$model
        capacity = battery$exp_capacity
        
        if (!is.na(model)) {
          model = paste0(" ", model)
        } else {
          model = ""
        }
        
        if (!is.na(capacity)) {
          capacity = sprintf(" %smAh", capacity)
        } else {
          capacity = ""
        }
        
        # Create the name string and append the data to it.
        name = sprintf("%s%s %sV%s @ %smA", battery$brand, model, battery$voltage, capacity, battery$current)
        batts[[length(batts) + 1]] = battery_discharge(name,
                                                       paste(datadir, type, battery$file, sep = "/"),
                                                       battery$current,
                                                       battery$cutoff,
                                                       battery$interval)
      }
    }
  }
  
  return(batts)
}

#' Plots the capacity of the batteries.
#' 
#' @param batts Battery data from `get_batteries`
#' @param show Vector with the batteries (index in batts) to be shown in the graph.
#' @seealso get_batteries
plot_mah <- function (batts, show = 1:length(batts)) {
  colourCount = length(show)
  getPalette = colorRampPalette(brewer.pal(9, "Set1"))
  
  graph = ggplot()
  #graph = graph + scale_colour_brewer(palette="Set1")
  graph + scale_fill_manual(values = getPalette(colourCount))
  graph = graph + theme(legend.title = element_blank(),
                        legend.justification = c(1, 1),
                        legend.position = c(1, 1))
  
  # Add the lines for each battery.
  for (i in 1:length(batts)) {
    for (j in 1:length(show)) {
      if (i == show[j]) {
        graph = graph + geom_line(data = batts[[i]],
                                  aes(x = mah, y = voltage, color = name))
      }
    }
  }

  # Setup labels and etc.
  graph = graph + scale_x_continuous("Capacity (mAh)",
                                     breaks = pretty_breaks(n = 15))
  graph = graph + scale_y_continuous("Voltage (V)",
                                     breaks = pretty_breaks(n = 15))
  
  # Plot the data.
  print(graph)
}

#' A shorthand for plot_mah(get_batteries(type, cached)).
#'
#' @param type Battery type.
#' @param cached Get the data from the cache or from the raw data dir.
plot_batteries <- function (type, cached = TRUE) {
  plot_mah(get_batteries(type, cached))
}

list_capacity <- function (type, cutoff = NULL) {
  prevmah = 0
  mah = 0
}
