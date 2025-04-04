<#-- @formatter:off -->
<#function getCodecType type>
  <#switch type?lower_case>
    <#case "string"><#return "Codec.STRING">
    <#case "number"><#return "Codec.DOUBLE">
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
    <#case "number"><#return "double">
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

<#function formatVariableValue var>
  <#local value = var.value!>
  <#local defaultValue = var.getType().getDefaultValue(generator.getWorkspace())>
  <#local javaType = var.getType().getJavaType(generator.getWorkspace())>

  <#if !value??>
    <#local value = defaultValue>
  </#if>

  <#if javaType == "String">
    <#if !value?starts_with('"') && !value?ends_with('"')>
      <#return "\"${value}\"">
    <#else>
      <#return value>
    </#if>
  <#else>
    <#return value>
  </#if>
</#function>

<#-- @formatter:on -->