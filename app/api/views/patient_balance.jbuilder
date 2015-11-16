json.array! @resp do |item|

  json.balance_type item['balance_type']
  json.unapplied_credit '%.2f' % item['unap_credit']
  json.unbilled '%.2f' % item['unbilled']
  json.current '%.2f' % item['current']
  json.greater_than_30 '%.2f' % item['greater_than_30']
  json.greater_than_60 '%.2f' % item['greater_than_60']
  json.greater_than_90 '%.2f' % item['greater_than_90']
  json.greater_than_120 '%.2f' % item['greater_than_120']
  json.total '%.2f' %  item['total']

end
