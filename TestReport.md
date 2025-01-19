# monadex campaign Contract integration and fizzing Report

## Critical Findings

### 1. Incorrect Mathematical Operations
**Location**: Lines 347 and 365  
**Severity**: Critical  
**Description**: Missing parentheses causing incorrect calculations and potential overflow.

**Affected Code**:
```solidity
// Before
return _fee.denominator * _amount / _fee.denominator + _fee.numerator;
return _reserveOut * _amountIn / _amountIn + _reserveIn;

// After
return (_fee.denominator * _amount) / (_fee.denominator + _fee.numerator);
return (_reserveOut * _amountIn) / (_amountIn + _reserveIn);
```

### 2. Unsafe Token Transfers
**Severity**: High  
**Description**: Usage of `transfer` and `transferFrom` instead of their safe counterparts.  
**Recommendation**: Implement `safeTransfer` and `safeTransferFrom` from OpenZeppelin's SafeERC20 library.

## Medium Findings

### 3. Missing Input Validation
**Severity**: Medium  
**Description**: Multiple instances lacking zero address and zero value checks.  
**Recommendation**: Implement proper input validation for all critical parameters.

### 4. Token Holder Tracking
**Severity**: Medium  
**Description**: No on-chain tracking mechanism for token holders and amounts.  
**Question**: Consider whether this should be implemented on-chain or handled by frontend.

## Low Findings

### 5. Fee Collection Issue
**Location**: `MonadexV1Campaigns.sol`, Line 339  
**Description**: Fee amount not being recorded in state variable.  
**Fix**:
```solidity
s_feeCollected += fee;
s_tokenDetails[_token].nativeReserve += msg.value - feeAmount;
```

### 6. Precision Loss in Bonding Curve
**Location**: Line 383  
**Description**: Precision loss preventing zero condition from being met.  
**Fix**:
```solidity
// Before
if (nativeAmountToCompleteBondingCurve == 0 ) {

// After
if (nativeAmountToCompleteBondingCurve <= OneDollar) {
```

### 7. Insufficient Allowance Handling
**Location**: Line 388  
**Description**: Function reverts due to insufficient allowance when bonding curve completion fails.  
**Fix**: Added state variable to track curve completion:
```solidity
s_curvedReached = true;
```

## Recommendations

### 8. Router Approval
**Location**: Line 424  
**Description**: Missing approval for router contract.  
**Implementation**:
```solidity
IERC20(_token).approve(i_monadexV1Router, type(uint256).max);
```

### 9. Contract Balance Monitoring
**Description**: Add function to monitor contract balance.  
**Implementation**:
```solidity
function getEtherBalance() 
    external 
    onlyOwner
    view  
    returns(uint256)
{
    return (address(this).balance);
}
```