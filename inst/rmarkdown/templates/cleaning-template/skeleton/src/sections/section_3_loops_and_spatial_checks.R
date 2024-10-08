
# cat(paste0("This section is only for assessments that includes loops and need to be checked with their respective calculations."))
# cat(paste0("Make sure to adjust variable names accordingly."))
# ## check for inconsistency in loops:
# 
# counts_loop1 <- raw.loop1 %>% 
#   group_by(uuid) %>% 
#   summarize(loop1_count = n())
# loop_counts_main <- raw.main %>% select(uuid, !!sym(enum_colname), date_interview, hh_size) %>% left_join(counts_loop1) %>% 
#   mutate(hh_size = ifelse(hh_size == "999", NA, as.numeric(hh_size))) %>% 
#   filter(hh_size > 1 & loop1_count %!=na% (hh_size - 1))
# 
# if(nrow(loop_counts_main) > 0){
#   # look at the loop_counts (perhaps just send a screenshot to AO)
#   loop_counts_main %>% view(title = "Inconsistencies in loop1")
#   # find loops for inconsistent uuids:
#   inconsistent_loop1 <- loop_counts_main %>% left_join(raw.loop1)
# }else{ cat("No inconsistencies with loops! :)") }
# 
# 
# # DECISION: what to do with these inconsistencies?
# 
# ids_to_clean <- c(
#   # put here the uuids for which *variable* should be adjusted
# )
# loop_indexes_to_delete <- c(
#   # put here the loop indexes which should be removed
#   
# )
# ids_to_delete <- c(
#   # uuids of submissions that will be totally removed
# 
# )
# 
# cleaning.log.loop_inconsitency <- loop_counts_main %>% 
#   filter(uuid %in% ids_to_clean) %>% 
#   mutate(variable = "hh_size", loop_index = NA,
#          old.value = as.character(hh_size), new.value = ifelse(is.na(loop1_count),"1",as.character(loop1_count + 1)), issue = "Inconsistency in number of entries in hh loop") %>% 
#   select(any_of(CL_COLS))
# 
# deletion.log.loop_inconsistency <- tibble()
# dl_inconsistency1 <- create.deletion.log(pull.raw(loop_indexes_to_delete), 
#                                                        enum_colname, "Inconsistency in number of entries in hh loop")
# dl_inconsistency2 <- create.deletion.log(pull.raw(ids_to_delete), 
#                                          enum_colname, "Inconsistency in number of entries in hh loop") %>% 
#   mutate(loop_index = NA)
# deletion.log.loop_inconsistency <- rbind(dl_inconsistency1, dl_inconsistency2)
# 
# ####################################################
# ## run this to delete/clean entries               ##
# raw.loop1 <- raw.loop1[!raw.loop1$loop_index %in% dl_inconsistency1$uuid,]
# ##                                                ##
# raw.main  <- raw.main[! (raw.main$uuid  %in% dl_inconsistency2$uuid),]
# raw.loop1 <- raw.loop1[!(raw.loop1$uuid %in% dl_inconsistency2$uuid),]
# raw.loop2 <- raw.loop2[!(raw.loop2$uuid %in% dl_inconsistency2$uuid),]
# ##                                                ##
# raw.main <- raw.main %>% apply.changes(cleaning.log.loop_inconsitency)
# ####################################################
# 
# deletion.log.new <- bind_rows(deletion.log.new, deletion.log.loop_inconsistency) %>% 
#   relocate(loop_index, .after = uuid)
# cleaning.log <- cleaning.log.loop_inconsitency   # a brand new cleaning log
# 
# cleaning.log <- tribble()
# 
# rm(ids_to_clean, loop_indexes_to_delete, counts_loop1)
# 
# #-------------------------------------------------------------------------------
# 
# ## GPS checks
# warning("No need to run if GPS checks is not needed.")
# 

if(geo_column  %in% names(raw.main)){
  suspicious_geo <- raw.main %>% 
    mutate(check = gsub(".*\\s(\\d+\\.\\d+)$", "\\1",!!sym(geo_column)),
           check = as.numeric(check)) %>%
    filter(check ==0) %>% 
    select(-check)
  
  if(nrow(suspicious_geo)>0){
    warning(paste0('Found ',nrow(suspicious_geo),' entries with suspicious coordinates'))
    
    deletion.log.coord <- utilityR::create.deletion.log(suspicious_geo,
                                                        directory_dictionary$enum_colname, 
                                                        "The geopoint accuracy is 0.0 may mean that the interview is fake.")
    
    write.xlsx(deletion.log.coord, make.filename.xlsx(directory_dictionary$dir.audits.check, "geospatial_check"),
               zoom = 90, firstRow = T)
    
  }
  
}


# Run the check if the point lies in the polygon

if(file.exists(polygon_file) & merge_column!=''){
  if(!merge_column %in% colnames(raw.main)){ 
    stop('The merge_column with polygon names is not present in your data')
  }else{
    # find if there are any "geopoint" variables in this data:
    if(!geo_column %in% names(raw.main)){ 
      stop('geo_column is not present in your dataset')
    }
  }
  sf_use_s2(TRUE)
  admin_boundary <- st_read(dsn = polygon_file)
  if(! polygon_file_merge_column %in% names(admin_boundary)){
    stop('The polygon_file_merge_column with polygon names is not present in your json file')
  } 
  admin_boundary_select <-  admin_boundary %>% 
    select(!!sym(polygon_file_merge_column)) %>% 
    rename(actual_location =!!sym(polygon_file_merge_column)) %>% 
    st_make_valid()
  
  
  if(omit_locations){
    ids_to_omit <- raw.main %>% filter(!!sym(location_column)%in% location_ids) %>% pull(uuid)
    raw.main_geo <- raw.main %>% filter(!uuid %in%ids_to_omit )
  }else{
    raw.main_geo <- raw.main
  }
  
  
  # TODO additional check for low precision??
  
  collected_pts <- raw.main_geo %>% 
    filter(!is.na(!!sym(geo_column))) %>%
    select(uuid, !!sym(directory_dictionary$enum_colname), !!sym(merge_column), !!sym(geo_column)) %>%
    rename(indicated_location = !!sym(merge_column)) %>% 
    rowwise() %>% 
    mutate(
      latitude =str_split(!!sym(geo_column), " ")[[1]][1],
      longitude = str_split(!!sym(geo_column), " ")[[1]][2],
    ) %>% 
    ungroup()
  
  # check if mostly all latitude is between the expected range
  if(!(
    sum(between(as.numeric(collected_pts$latitude),44,54))>0.90*nrow(collected_pts)&
    sum(between(as.numeric(collected_pts$longitude),22,41))>0.90*nrow(collected_pts))){
    # if not - rename them
    collected_pts <- collected_pts %>% 
      rename(longitude = latitude,
             latitude = longitude)
  }
  
  # set the crs and ensure they're the same
  collected_sf <- collected_pts %>% st_as_sf(coords = c('longitude','latitude'), crs = "+proj=longlat +datum=WGS84")
  admin_boundary_select <- st_transform(admin_boundary_select, crs = "+proj=longlat +datum=WGS84")
  admin_boundary_centers <- st_centroid(admin_boundary_select)%>% 
    mutate(lon_center = sf::st_coordinates(.)[,1],
           lat_center = sf::st_coordinates(.)[,2]) %>% 
    st_drop_geometry()
  
  if(!(
    sum(between(as.numeric(admin_boundary_centers$lat_center),44,54))>0.90*nrow(admin_boundary_centers)&
    sum(between(as.numeric(admin_boundary_centers$lon_center),22,41))>0.90*nrow(admin_boundary_centers))){
    # if not - rename them
    admin_boundary_centers <- admin_boundary_centers %>% 
      rename(lon_center = lat_center,
             lat_center = lon_center)
  }
  
  
  sf_use_s2(FALSE)
  
  spatial_join <- st_join(collected_sf, admin_boundary_select, join = st_within) %>%
    st_drop_geometry() %>% 
    left_join(admin_boundary_centers) %>% 
    rowwise() %>% 
    mutate(longitude = str_split(!!sym(geo_column), " ")[[1]][2],
           latitude =str_split(!!sym(geo_column), " ")[[1]][1],
           longitude=as.numeric(longitude),
           latitude = as.numeric(latitude))
  
  if(!(
    sum(between(as.numeric(spatial_join$latitude),44,54))>0.90*nrow(spatial_join)&
    sum(between(as.numeric(spatial_join$longitude),22,41))>0.90*nrow(spatial_join))){
    # if not - rename them
    spatial_join <- spatial_join %>% 
      rename(longitude = latitude,
             latitude = longitude)
  }
  
  spatial_join <- spatial_join %>% 
    mutate(distance_from_center = distHaversine(cbind(longitude,latitude), cbind(lon_center,lat_center))) %>% 
    ungroup() %>% 
    select(-c(longitude,latitude,lon_center,lat_center)) %>% 
    mutate(GPS_MATCH = case_when(
      is.na(actual_location) ~ "Outside polygon",
      actual_location == indicated_location ~ "Correct polygon", 
      .default = "Wrong polygon"
    ))
  
  
  
  if(any(spatial_join$GPS_MATCH !="Correct polygon")){
    
    check_spatial <- tibble(spatial_join) %>%
      filter(GPS_MATCH != "Correct polygon")
    # %>% view
    
    write.xlsx(check_spatial, make.filename.xlsx(directory_dictionary$dir.audits.check, "gps_checks"), overwrite = T)
    rm(collected_sf, spatial_join, check_spatial,admin_boundary,admin_boundary_select)
    warning('If the resulting distances look weird, please double check the order of of measures in the coordinate column, 
            sometimes long and lat are mixed up. This may mean a small change of the script')
  }else cat("All GPS points are matching their selected polygon :)")
}


if(use_audit==T){
  if( !exists('audits')){
    non_gis_check <- FALSE
    source('src/sections/section_2_3_x_helper_load_audits.R')
  }
  
  
  
  audits <- audits[audits$uuid %in% raw.main$uuid,]
  
  
  if(omit_locations){
    ids_to_omit <- raw.main %>% filter(!!sym(location_column)%in% location_ids) %>% pull(uuid)
    audits <- audits %>% filter(!uuid %in%ids_to_omit )
  }
  
  
  
  # general processing. CHeck warnings in case of any
  geo_processed_audits <- audits %>%
    dplyr::group_by(uuid) %>%
    dplyr::group_modify(~process.audit.geospatial(.x, start_q ='informed_consent', end_q = 'j2_1_barriers_access_education')) %>%
    dplyr::ungroup()   %>% 
    left_join(raw.main %>% select(uuid, directory_dictionary$enum_colname)) %>% 
    rename(col_enum = directory_dictionary$enum_colname)
  
  # get the cases of empty coordinates
  geo_processed_audits_issues <- geo_processed_audits %>% 
    filter(variable_explanation=='issue',
           !grepl('is not present for this uuid',issue)) %>% 
    select(where(~!all(is.na(.x))), -c(question,variable_explanation))
  
  general_table <- geo_processed_audits %>% 
    filter(!is.na(latitude)) %>% 
    filter(abs(0.6745 * (accuracy - median(accuracy, na.rm = T)) / 
                 median(abs(accuracy - median(accuracy, na.rm = T)), na.rm = T)) < 3) %>% 
    group_by(uuid) %>% 
    mutate(lagget_lat = lag(latitude),
           lagged_long = lag(longitude)
    ) %>% 
    mutate(time_difference = ((start-dplyr::lag(end))/60000)/60,
           distance = distHaversine(cbind(longitude,latitude), cbind(lagged_long,lagget_lat)),
           time_difference = ifelse(round(time_difference,2)==0, NA,time_difference ),
           distance = ifelse(distance%_<=_%(accuracy) | distance%_<=_%lag(accuracy), NA,distance),
           speed = round((distance/1000)/time_difference,2),
           distance = distance/1000
    ) %>% 
    select(-lagget_lat,-lagged_long) %>% 
    ungroup() %>% 
    filter(speed<300) %>% 
    mutate(start = as.POSIXct(start / 1000, origin = "1970-01-01"),
           end = as.POSIXct(end / 1000, origin = "1970-01-01"))
  
  # get the table with interview speeds for interviewers who were moving too fast
  summary_speed <- general_table %>% 
    group_by(uuid) %>% 
    mutate(max_speed = max(speed, na.rm = T)) %>% 
    filter(any(max_speed>=top_allowed_speed)) %>% 
    select(-max_speed) %>% 
    ungroup()
  # get the general table with average speed per problematic interviewer
  summary_speed_short <- summary_speed %>% 
    group_by(uuid) %>% 
    summarise(mean_speed = mean(speed, na.rm = T),
              col_enum = unique(col_enum))
  
  # fill up the excel file
  wb <- createWorkbook()
  addWorksheet(wb, "General table")
  addWorksheet(wb, "Audit issues summary")
  addWorksheet(wb, "Speed issues")
  addWorksheet(wb, "Speed issues summary")
  addWorksheet(wb, "Location issues")
  addWorksheet(wb, "Location issues summary")
  
  
  writeData(wb, "General table", general_table)
  writeData(wb, "Audit issues summary", geo_processed_audits_issues)
  writeData(wb, "Speed issues", summary_speed)
  writeData(wb, "Speed issues summary", summary_speed_short)
  
  
  # whether the points of the interview are in their correct squares
  
  # general checks
  if(!merge_column %in% colnames(raw.main)){ 
    stop('The merge_column with polygon names is not present in your data')
  }
  sf_use_s2(TRUE)
  admin_boundary <- st_read(dsn = polygon_file)
  if(! polygon_file_merge_column %in% names(admin_boundary)){
    stop('The polygon_file_merge_column with polygon names is not present in your json file')
  } 
  
  # select only geometry and the ID of the polygon and make valid
  admin_boundary_select <-  admin_boundary %>% 
    select(!!sym(polygon_file_merge_column)) %>% 
    st_make_valid()
  
  # select only needed columns from the general_table
  collected_pts <- general_table %>% 
    select(uuid, latitude,longitude,variable_explanation,question,col_enum) %>%
    left_join(raw.main %>% select(uuid,!!sym(merge_column)))
  
  
  # set the crs and ensure they're the same
  collected_sf <- collected_pts %>% st_as_sf(coords = c('longitude','latitude'), crs = "+proj=longlat +datum=WGS84")
  admin_boundary_select <- st_transform(admin_boundary_select, crs = "+proj=longlat +datum=WGS84")
  sf_use_s2(FALSE)
  
  spatial_join <- st_join(collected_sf, admin_boundary_select, join = st_within) %>%
    st_drop_geometry() %>% 
    mutate(GPS_MATCH = case_when(
      is.na(!!sym(polygon_file_merge_column)) ~ "Outside polygon",
      !!sym(polygon_file_merge_column) == !!sym(merge_column) ~ "Correct polygon", 
      .default = "Wrong polygon"
    ))
  
  
  if(any(spatial_join$GPS_MATCH !="Correct polygon")){
    
    check_spatial <- tibble(spatial_join) %>%
      group_by(uuid) %>% 
      filter(any(GPS_MATCH != "Correct polygon")) %>% 
      ungroup()
    
    summary_spatial <- check_spatial %>% 
      group_by(uuid) %>% 
      summarise(indicated_location = unique(!!sym(merge_column)),
                actual_location  = paste0(unique(!!sym(polygon_file_merge_column)) ,collapse = ', '),
                n_coordinates = n(),
                wrong_coordinates = length(GPS_MATCH[GPS_MATCH!="Correct polygon"]),
                col_enum = unique(col_enum)
      ) %>% 
      ungroup()
    
    writeData(wb, "Location issues", check_spatial)
    writeData(wb, "Location issues summary", summary_spatial)
    
    for(i in 1:6){setColWidths(wb, sheet = i, cols = 1:10, widths = "auto")}
    
    
  }else{
    cat("All GPS points are matching their selected polygon :)")
    for(i in 1:4){setColWidths(wb, sheet = i, cols = 1:10, widths = "auto")}
  }
  
  saveWorkbook(wb, make.filename.xlsx(directory_dictionary$dir.audits.check, "audit_checks_full"), overwrite = TRUE)
  
}



# 
# #-------------------------------------------------------------------------------
# 
# # run this section only if there is need to recode spatial data 
# 
# cleaning.log.spatial <- tibble()
# 
# if(country == "Poland"){
#   # for gps points outside Poland, set them to NA immediately
#   check_outside_POL <- check_spatial %>% filter(GPS_MATCH == "outside POL")
#   
#   cleaning.log.spatial <- rbind(cleaning.log.spatial, check_outside_POL %>% 
#     recode.set.NA.regex(gps_cols, ".*", "GPS point is falling outside of Poland"))
#   
#   # how about the other points?
#   check_wrong_admin2 <- check_spatial %>% filter(GPS_MATCH == "WRONG")
# }
# 
# # DECISION: what to do with these inconsistencies:
# 
# # for these uuids, admin2 will be recoded to match the geolocation:
# ids <- c(
#   ## POL
#   "1f43f45b-2dd8-4553-9d1d-a50dc79b841e",
#   "88ff086f-32dc-48c2-b791-b65e85246fa9",    
#   "e1cb77b8-abfe-485f-b3cd-709baa88c419"
#   ##
# )
# cl.spatial_recode <- check_wrong_admin4Pcode2 %>% filter(uuid %in% ids) %>%  
#   mutate(old.value = selected_admin2, new.value = within_admin2, variable = "admin2", issue = "Enumerator selected wrong poviat by mistake") %>% 
#   select(any_of(CL_COLS))
# 
# # for these uuids, remove geolocation data
# ids <- c(
#   
# )
# cl.spatial_remove_geo <- recode.set.NA.regex(pull.raw(ids), gps_cols, ".*", "Mismatch between selected admin2 and GPS location")
# 
# cleaning.log.spatial <- rbind(cleaning.log.spatial, cl.spatial_recode, cl.spatial_remove_geo)
# 
# # do we remove any suspicious surveys because of GPS mismatch?
# ids_remove <- c(
#   
# )
# deletion.log.new <- rbind(deletion.log.new,
#                           create.deletion.log(pull.raw(ids_remove), enum_colname, "Mismatch between selected admin2 and GPS location"))
# 
# # ------------------------------------
# raw.main <- raw.main %>% apply.changes(cleaning.log.spatial)
# cleaning.log <- bind_rows(cleaning.log, cleaning.log.spatial)

#################################################
# raw.main  <- raw.main[! (raw.main$uuid  %in% deletion.log.new$uuid),]
# raw.loop1 <- raw.loop1[!(raw.loop1$uuid %in% deletion.log.new$uuid),]
# # raw.loop2 <- raw.loop2[!(raw.loop2$uuid %in% deletion.log.new$uuid),]
# #################################################
# 
# # deletion log should be now finalized
# 
# # Save deletion.log file
# #deletion.log.whole <- rbind(deletion.log.previous, deletion.log.new)
# #write.xlsx(deletion.log.whole, make.filename.xlsx("output/deletion_log/", "deletion_log", no_date = T), overwrite=T)
# write.xlsx(deletion.log.new, make.filename.xlsx("output/deletion_log/", "deletion_log", no_date = T), overwrite=T)