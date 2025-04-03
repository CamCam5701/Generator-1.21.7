<#-- @formatter:off -->
<#function getCodecType type>
  <#switch type?lower_case>
    <#case "string"><#return "Codec.STRING">
    <#case "number"><#return "Codec.INT">
    <#case "logic"><#return "Codec.BOOL">
    <#case "itemstack"><#return "ItemStack.CODEC">
    <#case "direction"><#return "Direction.CODEC">
    <#case "blockstate"><#return "BlockState.CODEC">
    <#default><#return "Codec.STRING">
  </#switch>
</#function>

<#function getJavaType type>
  <#switch type?lower_case>
    <#case "string"><#return "String">
    <#case "number"><#return "int">
    <#case "logic"><#return "boolean">
    <#case "itemstack"><#return "ItemStack">
    <#case "direction"><#return "Direction">
    <#case "blockstate"><#return "BlockState">
    <#default><#return "Object">
  </#switch>
</#function>

<#function getDefaultValue type>
  <#switch type?lower_case>
    <#case "string"><#return "\"\"">
    <#case "number"><#return "0">
    <#case "logic"><#return "false">
    <#case "itemstack"><#return "ItemStack.EMPTY">
    <#case "direction"><#return "Direction.NORTH">
    <#case "blockstate"><#return "Blocks.AIR.defaultBlockState()">
    <#default><#return "null">
  </#switch>
</#function>
<#-- @formatter:on -->