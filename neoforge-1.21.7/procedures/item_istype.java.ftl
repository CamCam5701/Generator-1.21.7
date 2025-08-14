<#include "mcitems.ftl">
<#include "mcelements.ftl">
(${mappedMCItemToItemStackCode(input$item, 1)}.is(${generator.map(field$item_type, "itemtypes")}))