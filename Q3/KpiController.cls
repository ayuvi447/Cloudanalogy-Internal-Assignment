public with sharing class KpiController {

    // KPI Summary — region ke basis pe data laata hai
    @AuraEnabled(cacheable=false)
    public static Map<String, Object> getKpiSummary(String region) {
        Map<String, Object> result = new Map<String, Object>();

        // WHERE clause — 'All' select kiya toh koi filter nahi
        String regionFilter = (region != 'All' && region != null)
            ? ' AND Account.BillingState = :region ' : ' ';

        // Open Pipeline
        String pipelineQuery = 'SELECT SUM(Amount) total FROM Opportunity ' +
            'WHERE StageName NOT IN (\'Closed Won\',\'Closed Lost\') ' +
            'AND IsClosed = false' + regionFilter;
        AggregateResult[] pipelineResult = Database.query(pipelineQuery);
        result.put('openPipeline', pipelineResult[0].get('total') ?? 0);

        // Won Revenue
        String wonQuery = 'SELECT SUM(Amount) total FROM Opportunity ' +
            'WHERE IsWon = true' + regionFilter;
        AggregateResult[] wonResult = Database.query(wonQuery);
        result.put('wonRevenue', wonResult[0].get('total') ?? 0);

        // Average Deal Size
        String avgQuery = 'SELECT AVG(Amount) avg FROM Opportunity ' +
            'WHERE IsClosed = false' + regionFilter;
        AggregateResult[] avgResult = Database.query(avgQuery);
        result.put('avgDealSize', avgResult[0].get('avg') ?? 0);

        // Win Rate — Won / (Won + Lost) * 100
        String totalClosedQuery = 'SELECT COUNT() FROM Opportunity ' +
            'WHERE IsClosed = true' + regionFilter;
        String wonCountQuery = 'SELECT COUNT() FROM Opportunity ' +
            'WHERE IsWon = true' + regionFilter;
        Integer totalClosed = Database.countQuery(totalClosedQuery);
        Integer wonCount    = Database.countQuery(wonCountQuery);
        Decimal winRate = totalClosed > 0
            ? ((Decimal)wonCount / totalClosed * 100).setScale(1) : 0;
        result.put('winRate', winRate);

        return result;
    }

    // Detail Panel — Top 5 Opportunities
    @AuraEnabled(cacheable=true)
    public static List<Opportunity> getTopOpportunities(String region, String kpiType) {
        String regionFilter = (region != 'All' && region != null)
            ? ' AND Account.BillingState = :region ' : ' ';

        String query = 'SELECT Id, Name, Amount, StageName, CloseDate, Account.Name ' +
            'FROM Opportunity WHERE IsClosed = false' +
            regionFilter +
            'ORDER BY Amount DESC LIMIT 5';
        return Database.query(query);
    }
}