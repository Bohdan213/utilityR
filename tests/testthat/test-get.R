testthat::test_that("get.type works test 1 - gives warning when needed", {
  filename <- testthat::test_path("fixtures","tool.xlsx")
  label_colname <- "label::English"
  tool.survey <- utilityR::load.tool.survey(filename,label_colname)
  testthat::expect_error(get.type("a2_partner"),"tool.survey is not provided.")
})

testthat::test_that("get.type works test 2 - works as expected", {
  filename <- testthat::test_path("fixtures","tool.xlsx")
  label_colname <- "label::English"
  tool.survey <- utilityR::load.tool.survey(filename,label_colname)

  testthat::expect_equal(get.type("a2_partner",tool.survey),"select_one")
})

testthat::test_that("get.type works test 3 - warning for missing variables when needed", {
    filename <- testthat::test_path("fixtures","tool.xlsx")
    label_colname <- "label::English"
    tool.survey <- utilityR::load.tool.survey(filename,label_colname)


  testthat::expect_warning(get.type("a_partner",tool.survey), 'Variables not found in tool.survey: a_partner')
})

testthat::test_that("get.label works test 1 - error when no tool is provided", {
  filename <- testthat::test_path("fixtures","tool.xlsx")
  label_colname <- "label::English"
  tool.survey <- utilityR::load.tool.survey(filename,label_colname)
  testthat::expect_error(get.label("a2_partner",label_colname = label_colname),"tool.survey is not provided.")
})

testthat::test_that("get.label works test 2 - error when no label is provided", {
  filename <- testthat::test_path("fixtures","tool.xlsx")
  label_colname <- "label::English"
  tool.survey <- utilityR::load.tool.survey(filename,label_colname)

  testthat::expect_error(get.label("a2_partner",tool.survey = tool.survey),"label_colname is not provided.")
})

testthat::test_that("get.label works test 3 - desired output", {
  filename <- testthat::test_path("fixtures","tool.xlsx")
  label_colname <- "label::English"
  tool.survey <- utilityR::load.tool.survey(filename,label_colname)

  actual_output <- get.label("b17_access_stores/test",label_colname = label_colname,tool.survey = tool.survey) %>%
    suppressWarnings()
  testthat::expect_equal(actual_output,"B17_How have the war and its related developments affected your ability to access your usual store or marketplace this month?")
  testthat::expect_equal(get.label("a2_partner",label_colname,tool.survey),"A2_Partner name")
  testthat::expect_warning(get.label("a_partner",label_colname,tool.survey))
})

testthat::test_that("get.choice.label work - test 1 throws error when tool is not provided", {
  filename <- testthat::test_path("fixtures","tool.xlsx")
  label_colname <- "label::English"
  tool.choices <- utilityR::load.tool.choices(filename,label_colname)

  testthat::expect_error(get.choice.label("yes",list = "yn",label_colname = label_colname),
                         "tool.choices is not provided.")
})

testthat::test_that("get.choice.label work - test 2 throws error when list name is not provided", {
  filename <- testthat::test_path("fixtures","tool.xlsx")
  label_colname <- "label::English"
  tool.choices <- utilityR::load.tool.choices(filename,label_colname)

  testthat::expect_error(get.choice.label("yes",list = "yn",tool.choices = tool.choices),
                         "label_colname is not provided.")
})

testthat::test_that("get.choice.label work - test 3 throws error when list name is wrong", {
  filename <- testthat::test_path("fixtures","tool.xlsx")
  label_colname <- "label::English"
  tool.choices <- utilityR::load.tool.choices(filename,label_colname)

  testthat::expect_error(get.choice.label("yes",list="y",tool.choices = tool.choices,label_colname = label_colname),
                         "list y not found in tool.choices!")
})

testthat::test_that("get.choice.label work - test 4 desired output", {
  filename <- testthat::test_path("fixtures","tool.xlsx")
  label_colname <- "label::English"
  tool.choices <- utilityR::load.tool.choices(filename,label_colname)

  testthat::expect_equal(get.choice.label("yes","yn",label_colname,tool.choices),"Yes")
  testthat::expect_warning(get.choice.label("ye","yn",label_colname,tool.choices))
})


testthat::test_that("get.choice.name.from.label work test 1 - error when no tool choices", {
  filename <- testthat::test_path("fixtures","tool.xlsx")
  label_colname <- "label::English"
  tool.choices <- utilityR::load.tool.choices(filename,label_colname)

  testthat::expect_error(get.choice.name.from.label("Yes",list = "yn",label_colname = label_colname),
                         "tool.choices is not provided.")
})

testthat::test_that("get.choice.name.from.label work test 2 - error when no label", {
  filename <- testthat::test_path("fixtures","tool.xlsx")
  label_colname <- "label::English"
  tool.choices <- utilityR::load.tool.choices(filename,label_colname)

  testthat::expect_error(get.choice.name.from.label("Yes",list = "yn",tool.choices = tool.choices),
                         "label_colname is not provided.")
})

testthat::test_that("get.choice.name.from.label work test 3 - error list is wrong", {
  filename <- testthat::test_path("fixtures","tool.xlsx")
  label_colname <- "label::English"
  tool.choices <- utilityR::load.tool.choices(filename,label_colname)

  testthat::expect_error(get.choice.name.from.label("Yes",list="y",
                                                    tool.choices = tool.choices,
                                                    label_colname = label_colname),
                         ("list y not found in tool.choices!"))
})

testthat::test_that("get.choice.name.from.label work test 4 - desired functionality", {
  filename <- testthat::test_path("fixtures","tool.xlsx")
  label_colname <- "label::English"
  tool.choices <- utilityR::load.tool.choices(filename,label_colname)

  testthat::expect_equal(get.choice.name.from.label("Yes","yn",label_colname,tool.choices),"yes")
  testthat::expect_warning(
    get.choice.name.from.label("Ye","yn",label_colname,tool.choices)
    )
})


testthat::test_that("get.choice.list.from.name work , test 1 - error when no tool.survey provided", {
  filename <- testthat::test_path("fixtures","tool.xlsx")
  label_colname <- 'label::English'
  tool.survey <- utilityR::load.tool.survey(filename,label_colname=label_colname)
  testthat::expect_error(get.choice.list.from.name("a2_partner"),"tool.survey is not provided.")
})

testthat::test_that("get.choice.list.from.name work , test 3 - desired functionality", {
  filename <- testthat::test_path("fixtures","tool.xlsx")
  label_colname <- 'label::English'
  tool.survey <- utilityR::load.tool.survey(filename,label_colname=label_colname)

  testthat::expect_warning(get.choice.list.from.name("a_partner",tool.survey))

  testthat::expect_equal(get.choice.list.from.name("a2_partner",tool.survey),"partner")
  actual_output <- get.choice.list.from.name("b17_access_stores/test",tool.survey) %>%
    suppressWarnings()
  testthat::expect_equal(actual_output,"affect")

})

testthat::test_that("get.choice.list.from.type works", {
  testthat::expect_equal(get.choice.list.from.type("select_one a2_partner"),"a2_partner")
  testthat::expect_equal(get.choice.list.from.type("text"),NA)
})

testthat::test_that("get.ref.question works", {
  testthat::expect_equal(get.ref.question("selected(${b17_access_stores}, 'other')"),"b17_access_stores")
})

testthat::test_that("get.select.db works test 1 - error when no tool survey are provided", {
  filename <- testthat::test_path("fixtures","tool.xlsx")
  label_colname <- "label::English"
  tool.survey <- utilityR::load.tool.survey(filename,label_colname)
  tool.choices <- utilityR::load.tool.choices(filename,label_colname)
  testthat::expect_error(get.select.db(label_colname = label_colname,tool.choices = tool.choices),
                         "tool.survey is not provided.")
})

testthat::test_that("get.select.db works test 2 - error when no tool choices are provided", {
  filename <- testthat::test_path("fixtures","tool.xlsx")
  label_colname <- "label::English"
  tool.survey <- utilityR::load.tool.survey(filename,label_colname)
  tool.choices <- utilityR::load.tool.choices(filename,label_colname)

  testthat::expect_error(get.select.db(label_colname = label_colname,tool.survey = tool.survey),
                         "tool.choices is not provided.")
})

testthat::test_that("get.select.db works test 3 - error when no label provided", {
  filename <- testthat::test_path("fixtures","tool.xlsx")
  label_colname <- "label::English"
  tool.survey <- utilityR::load.tool.survey(filename,label_colname)
  tool.choices <- utilityR::load.tool.choices(filename,label_colname)

  testthat::expect_error(get.select.db(tool.choices = tool.choices,tool.survey = tool.survey),
                         "label_colname is not provided.")

})
testthat::test_that("get.select.db works test 4 - desired functionality", {
  filename <- testthat::test_path("fixtures","tool.xlsx")
  label_colname <- "label::English"
  tool.survey <- utilityR::load.tool.survey(filename,label_colname)
  tool.choices <- utilityR::load.tool.choices(filename,label_colname)

  expected_output <- data.frame(type = c("select_one partner","select_one yn","select_multiple affect"),
                                name = c("a2_partner","b3_is_this_a_test","b17_access_stores"),
                                q.label = c("A2_Partner name",
                                            "Is this a test?",
                                            "B17_How have the war and its related developments affected your ability to access your usual store or marketplace this month?"),
                                q.type = c("select_one","select_one","select_multiple"),
                                list_name = c("partner","yn","affect"),
                                choices = c("Caritas;\nSave_the_Children;\nCORE;\nACTED;\nKIIS;\nJERU;\nFAO;\nACF;\nPIN;\nIRC;\nWFP;\nREACH;\nUFF_ERC;\nTGH;\nMercy_Corps;\nURCS;\nHEKS_EPER;\nEquilibrium;\nZT;\nUNOPS;\nLASKA;\nDorcas;\nNew_Partner;\nAdditional_Partner;\nWVI;\nGlobal_Communities",
                                            "yes;\nno",
                                            "no_impact;\nmovement_restrictions;\nfighting_shelling"),
                                choices.label = c("Caritas;\nSave_the_Children;\nCORE;\nACTED;\nKIIS;\nJERU;\nFAO;\nACF;\nPIN;\nIRC;\nWFP;\nREACH;\nUFF_ERC;\nTGH;\nMercy_Corps;\nURCS;\nHEKS_EPER;\nEquilibrium;\nZT;\nUNOPS;\nLASKA;\nDorcas;\nNew_Partner;\nAdditional_Partner;\nWVI;\nGlobal_Communities",
                                                  "Yes;\nNo",
                                                  "No impact on physical access to stores or marketplaces;\nMovement restrictions related to martial law;\nActive fighting or shelling in the area"))
  actual_output <- get.select.db(tool.choices = tool.choices,label_colname = label_colname,tool.survey = tool.survey) %>%
    suppressWarnings()
  testthat::expect_equal(actual_output,expected_output)
})


testthat::test_that("get.other.db works - test 1 error when tool.survey is missing", {
  filename <- testthat::test_path("fixtures","tool.xlsx")
  label_colname <- "label::English"
  tool.survey <- utilityR::load.tool.survey(filename,label_colname)
  tool.choices <- utilityR::load.tool.choices(filename,label_colname)
  testthat::expect_error(get.other.db(label_colname = label_colname,tool.choices = tool.choices),
                         "tool.survey is not provided.")
})

testthat::test_that("get.other.db works - test 2 error when tool.choices is missing", {
  filename <- testthat::test_path("fixtures","tool.xlsx")
  label_colname <- "label::English"
  tool.survey <- utilityR::load.tool.survey(filename,label_colname)
  tool.choices <- utilityR::load.tool.choices(filename,label_colname)

  testthat::expect_error(get.other.db(label_colname = label_colname,tool.survey = tool.survey),
                         "tool.choices is not provided.")
})

testthat::test_that("get.other.db works - test 3 error when label is missing", {
  filename <- testthat::test_path("fixtures","tool.xlsx")
  label_colname <- "label::English"
  tool.survey <- utilityR::load.tool.survey(filename,label_colname)
  tool.choices <- utilityR::load.tool.choices(filename,label_colname)

  testthat::expect_error(get.other.db(tool.choices = tool.choices,tool.survey = tool.survey),
                         "label_colname is not provided.")
})

testthat::test_that("get.other.db works - test 4 desired functionality", {
  filename <- testthat::test_path("fixtures","tool.xlsx")
  label_colname <- "label::English"
  tool.survey <- utilityR::load.tool.survey(filename,label_colname)
  tool.choices <- utilityR::load.tool.choices(filename,label_colname)

  expected_output <- data.frame(name = c("b17_1_access_stores_other"),
                                ref.name = c("b17_access_stores"),
                                full.label = c("B17_How have the war and its related developments affected your ability to access your usual store or marketplace this month? - B17_1_Other (specify)"),
                                ref.type = c("select_multiple"),
                                choices = c("no_impact;\nmovement_restrictions;\nfighting_shelling"),
                                choices.label = c("No impact on physical access to stores or marketplaces;\nMovement restrictions related to martial law;\nActive fighting or shelling in the area"))
  actual_output <- get.other.db(tool.choices = tool.choices,label_colname = label_colname,tool.survey = tool.survey)%>%
    suppressWarnings()
  testthat::expect_equal(actual_output,expected_output)
})

testthat::test_that("get.trans.db works - test 1 breaks when tool.survey is not provided", {
  filename <- testthat::test_path("fixtures","tool.xlsx")
  label_colname <- "label::English"
  tool.survey <- utilityR::load.tool.survey(filename,label_colname)
  tool.choices <- utilityR::load.tool.choices(filename,label_colname)
  testthat::expect_error(get.trans.db(label_colname = label_colname,tool.choices = tool.choices),
                         "tool.survey is not provided.")
})

testthat::test_that("get.trans.db works - test 2 breaks when tool.choices is not provided", {
  filename <- testthat::test_path("fixtures","tool.xlsx")
  label_colname <- "label::English"
  tool.survey <- utilityR::load.tool.survey(filename,label_colname)
  tool.choices <- utilityR::load.tool.choices(filename,label_colname)

  testthat::expect_error(get.trans.db(label_colname = label_colname,tool.survey = tool.survey),
                         "tool.choices is not provided.")
})

testthat::test_that("get.trans.db works - test 3 breaks when label is not provided", {
  filename <- testthat::test_path("fixtures","tool.xlsx")
  label_colname <- "label::English"
  tool.survey <- utilityR::load.tool.survey(filename,label_colname)
  tool.choices <- utilityR::load.tool.choices(filename,label_colname)

  testthat::expect_error(get.trans.db(tool.choices = tool.choices,tool.survey = tool.survey),
                         "label_colname is not provided.")
})

testthat::test_that("get.trans.db works - test 4 desired functionality", {
  filename <- testthat::test_path("fixtures","tool.xlsx")
  label_colname <- "label::English"
  tool.survey <- utilityR::load.tool.survey(filename,label_colname)
  tool.choices <- utilityR::load.tool.choices(filename,label_colname)

  expected_output <- data.frame(name = c("individuals_comments"),
                                label = c("Any comments"))
  attr(expected_output, 'row.names') <- as.integer(10)
  actual_output <- get.trans.db(tool.choices = tool.choices,label_colname = label_colname,tool.survey = tool.survey)%>%
    suppressWarnings()
  testthat::expect_equal(actual_output,expected_output)
})



testthat::test_that("get.text.db works - test 1 desired functionality", {
  filename <- testthat::test_path("fixtures","tool.xlsx")
  label_colname <- "label::English"
  tool.survey <- utilityR::load.tool.survey(filename,label_colname)
  tool.choices <- utilityR::load.tool.choices(filename,label_colname)

  expected_output <- data.frame(name = c("individuals_comments",'b17_1_access_stores_other'),
                                ref.name = c(NA,'b17_access_stores'),
                                full.label = c("Any comments",
                                               'B17_How have the war and its related developments affected your ability to access your usual store or marketplace this month? - B17_1_Other (specify)'),
                                ref.type = c(NA, 'select_multiple'),
                                choices = c(NA, "no_impact;\nmovement_restrictions;\nfighting_shelling"),
                                choices.label = c(NA, "No impact on physical access to stores or marketplaces;\nMovement restrictions related to martial law;\nActive fighting or shelling in the area")
                                )
  actual_output <- get.text.db(tool.choices = tool.choices,label_colname = label_colname,tool.survey = tool.survey) %>%
    suppressWarnings()
  testthat::expect_equal(actual_output,expected_output)
})


testthat::test_that("get.text.db works - test 2 breaks when tool.survey is not provided", {
  filename <- testthat::test_path("fixtures","tool.xlsx")
  label_colname <- "label::English"
  tool.survey <- utilityR::load.tool.survey(filename,label_colname)
  tool.choices <- utilityR::load.tool.choices(filename,label_colname)
  testthat::expect_error(get.text.db(label_colname = label_colname,tool.choices = tool.choices),
                         "tool.survey is not provided.")
})

testthat::test_that("get.text.db works - test 3 breaks when tool.choices is not provided", {
  filename <- testthat::test_path("fixtures","tool.xlsx")
  label_colname <- "label::English"
  tool.survey <- utilityR::load.tool.survey(filename,label_colname)
  tool.choices <- utilityR::load.tool.choices(filename,label_colname)

  testthat::expect_error(get.text.db(label_colname = label_colname,tool.survey = tool.survey),
                         "tool.choices is not provided.")
})

testthat::test_that("get.text.db works - test 4 breaks when label is not provided", {
  filename <- testthat::test_path("fixtures","tool.xlsx")
  label_colname <- "label::English"
  tool.survey <- utilityR::load.tool.survey(filename,label_colname)
  tool.choices <- utilityR::load.tool.choices(filename,label_colname)

  testthat::expect_error(get.text.db(tool.choices = tool.choices,tool.survey = tool.survey),
                         "label_colname is not provided.")
})











