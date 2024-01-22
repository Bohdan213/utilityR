cleaning.log <- data.frame()

if(name_clean_others_file != ''){
  or.edited  <- utilityR::load.requests(directory_dictionary$dir.requests, 
                                        name_clean_others_file,
                                        sheet = sheet_name_others, validate = T)  # specify Sheet2 because the first one is a readme
  
  or.edited <- or.edited %>%
    left_join(tool.survey %>% select(name,list_name) %>% rename(ref.name=name)) %>% 
    dplyr::rowwise() %>%
    dplyr::mutate(existing.v.choice_label = sapply(stringr::str_split(choice, " "), function(choice_list) {
      if (is.na(existing.v)) {
        return("NA")
      }
      existing.v.list <- unlist(strsplit(existing.v, ";"))
      
      for (ch in choice_list) {
        if ((list_name %in% tool.choices$list_name)) {
          label <- utilityR::get.choice.label(ch, list_name,
                                              directory_dictionary$label_colname, tool.choices)
          if ((is.element(label, existing.v.list))) {
            existing.v.list <- existing.v.list[!existing.v.list %in% label]
          }
        } else {
          stop(paste0("The choice list ", list_name, " does not exist in the tool.choices file"))
        }
      }
      return(paste(existing.v.list, collapse = ";"))
    })) %>%
    dplyr::ungroup() %>%
    mutate(existing.v = ifelse(existing.v.choice_label == '', NA, existing.v.choice_label),
           invalid.v = ifelse(existing.v.choice_label == '', 'YES', invalid.v))
  
  warn <- nrow(or.edited[or.edited$existing.v.choice_label =='',])
  
  or.edited <- or.edited%>%
    dplyr::select(-existing.v.choice_label)
  
  if(warn>0){
    warning(paste0(warn,' of the entries in the existing column of the requests file were already 
chosen by the respondent in the cumulative column. These `other` enries will be coded
as invalid to speed up the recoding process'))
  }
  
  if(any(or.edited$check == 1)){
    issue <- paste0('uuid: ', or.edited[or.edited$check == 1,]$uuid,', variable: ',or.edited[or.edited$check == 1,]$name)
    stop(paste0('Some of your entries have errors, please double-check: ', paste0(issue,collapse = '\n')))
  }
  
  if(any(or.edited$check == 3)){
    issue <- paste0('uuid: ', or.edited[or.edited$check == 3,]$uuid,', variable: ',or.edited[or.edited$check == 3,]$name)
    stop(paste0('Some of your entries are empty, please double-check: ', paste0(issue,collapse = '\n')))
  }
  
  consistency_check <- or.edited %>% select(uuid, existing.v, ref.name) %>% filter(!is.na(existing.v)) %>% 
    tidyr::separate_rows(existing.v  , sep= "[;\r\n]") %>% 
    mutate(existing.v = trimws(existing.v)) %>% 
    filter(!existing.v=='') %>% 
    left_join((tool.survey %>% select(name, list_name)), join_by(ref.name==name )) %>% 
    anti_join(tool.choices %>% select(list_name,directory_dictionary$label_colname) %>% 
                rename('existing.v'=directory_dictionary$label_colname))
  
  
  if(nrow(consistency_check)>0){
    stop("Some of the choices that you've selected in the recode.others file do not match the labels that you have in your
         tool. Please check the consistency_check object for more details")
  }
  
  
  
  # run the bits below
  
  # separate the other translations to fit each individual dataframe that you have - no unnecessary variables in each
  raw.main_requests <- or.edited %>% 
    filter(name %in% names(raw.main))
  if(exists('raw.loop1')){
    raw.loop1_requests <- or.edited %>% 
      filter(name %in% names(raw.loop1))
    if(nrow(raw.loop1_requests)==0){
      rm(raw.loop1_requests)
    }
  }
  if(exists('raw.loop2')){
    raw.loop2_requests <- or.edited %>% 
      filter(name %in% names(raw.loop2))
    if(nrow(raw.loop2_requests)==0){
      rm(raw.loop2_requests)
    }
  }
  if(exists('raw.loop3')){
    raw.loop3_requests <- or.edited %>% 
      filter(name %in% names(raw.loop3))
    if(nrow(raw.loop3_requests)==0){
      rm(raw.loop3_requests)
    }
  }
  
  
  # If you face any weird double spaces
  tool.choices$`label::English`=str_squish(tool.choices$`label::English`)
  
  # Create a cleaning log file for each loop if there's a need for it.
  cleaning.log.other.main <- utilityR::recode.others(data = raw.main,
                                                     or.edited = raw.main_requests,
                                                     orig_response_col = 'responses',
                                                     is.loop = F,
                                                     tool.choices = tool.choices,
                                                     tool.survey = tool.survey)
  
  if(exists('raw.loop1_requests')){
    cleaning.log.other.loop1 <- utilityR::recode.others(data = raw.loop1,
                                                        or.edited = raw.loop1_requests,
                                                        orig_response_col = 'responses',
                                                        is.loop = T,
                                                        tool.choices = tool.choices,
                                                        tool.survey = tool.survey)
  }else{cleaning.log.other.loop1 <- data.frame()}
  
  if(exists('raw.loop2_requests')){
    cleaning.log.other.loop2 <- utilityR::recode.others(data = raw.loop2,
                                                        or.edited = raw.loop2_requests,
                                                        orig_response_col = 'responses',
                                                        is.loop = T,
                                                        tool.choices = tool.choices,
                                                        tool.survey = tool.survey)
  }else{cleaning.log.other.loop2 <- data.frame()}
  if(exists('raw.loop3_requests')){
    cleaning.log.other.loop3 <- utilityR::recode.others(data = raw.loop3,
                                                        or.edited = raw.loop3_requests,
                                                        orig_response_col = 'responses',
                                                        is.loop = T,
                                                        tool.choices = tool.choices,
                                                        tool.survey = tool.survey)
  }else{cleaning.log.other.loop3 <- data.frame()}
  
  
  ## Apply changes from the cleaning log onto our raw data
  raw.main <- utilityR::apply.changes(raw.main, clog = cleaning.log.other.main,is.loop = F)
  
  if(nrow(cleaning.log.other.loop1>0)){
    raw.loop1 <- utilityR::apply.changes(raw.loop1,clog = cleaning.log.other.loop1,is.loop = T)
  }
  if(nrow(cleaning.log.other.loop2>0)){
    raw.loop2 <- utilityR::apply.changes(raw.loop2,clog = cleaning.log.other.loop2,is.loop = T)
  }
  if(nrow(cleaning.log.other.loop3>0)){
    raw.loop3 <- utilityR::apply.changes(raw.loop3,clog = cleaning.log.other.loop3,is.loop = T)
  }
  
  # Create the cleaning log for recoding others
  cleaning.log.other <- rbind(cleaning.log.other.main,cleaning.log.other.loop1,
                              cleaning.log.other.loop2,
                              cleaning.log.other.loop3
  )
  # bind it with the main cleaning log
  cleaning.log <- bind_rows(cleaning.log, cleaning.log.other)
  cleaning.log <- cleaning.log %>% select(-uniqui)
}

### Add translation cleaning if needed. ------------------------------ 

if(name_clean_trans_file!= ''){
  
  trans <-  utilityR::load.requests(directory_dictionary$dir.requests, name_clean_trans_file, validate = F)
  
  # run the bits below
  cleaning.log.trans <- utilityR::recode.trans.requests(trans, response_col = 'responses')
  
  # Separate the cleaning log files so that we only apply changes to those data that need it.
  raw.main_trans <- cleaning.log.trans %>% 
    filter(variable %in% names(raw.main))
  
  if(exists('raw.loop1')){
    raw.loop1_trans <- cleaning.log.trans %>% 
      filter(variable %in% names(raw.loop1))
  }
  if(exists('raw.loop2')){
    raw.loop2_trans <- cleaning.log.trans %>% 
      filter(variable %in% names(raw.loop2))
  }
  if(exists('raw.loop3')){
    raw.loop3_trans <- cleaning.log.trans %>% 
      filter(variable %in% names(raw.loop3))
  }
  
  # apply changes to the frame
  raw.main <- utilityR::apply.changes(raw.main,clog = raw.main_trans,is.loop = F)
  if(exists('raw.loop1_trans')){
    if(nrow(raw.loop1_trans)>0){
      raw.loop1 <- utilityR::apply.changes(raw.loop1,clog = raw.loop1_trans,is.loop = T)
      
    }
  }
  if(exists('raw.loop2_trans')){
    if(nrow(raw.loop2_trans)>0){
      raw.loop2 <- utilityR::apply.changes(raw.loop2,clog = raw.loop2_trans,is.loop = T)
    }
  }
  if(exists('raw.loop3_trans')){
    if(nrow(raw.loop3_trans)>0){
      raw.loop3 <- utilityR::apply.changes(raw.loop3,clog = raw.loop3_trans,is.loop = T)
    }
  }
  cleaning.log <- bind_rows(cleaning.log, cleaning.log.trans)
  
}